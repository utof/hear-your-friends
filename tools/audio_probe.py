#!/usr/bin/env python3
"""Measure a quiet synthetic tone through PulseAudio/PipeWire, optionally through game loopback.

Game mode requires one running world with microphone loopback enabled. Only that
process's streams are moved. Original routes and mod configuration are restored.
No recording is retained and the system default audio devices are never changed.
"""
import argparse
from contextlib import contextmanager
import json
from pathlib import Path
import re
import subprocess
import tempfile
import time
import wave

import numpy as np
from dev import DEFAULT_GAME, configure, mod_dir, write_changed

RATE = 48000
FREQUENCY = 997


def pactl(*args):
    return subprocess.check_output(['pactl', *map(str, args)], text=True).strip()


def streams(kind, pattern):
    return [s for s in json.loads(pactl('--format=json', 'list', kind))
            if re.search(pattern, ' '.join(str(s.get('properties', {}).get(key, '')) for key in ('application.name', 'application.process.binary')), re.I)]


def tone_rms(samples):
    if len(samples) < RATE:
        raise RuntimeError('Audio capture is too short.')
    mono = samples.reshape(-1, 2).mean(axis=1)
    mono = mono[len(mono)//4:3*len(mono)//4]
    window = np.hanning(len(mono))
    spectrum = np.fft.rfft(mono * window)
    frequencies = np.fft.rfftfreq(len(mono), 1 / RATE)
    band = np.abs(frequencies - FREQUENCY) <= 12
    return float(np.sqrt(2 * np.sum(np.abs(spectrum[band])**2) /
                         (len(mono)**2 * np.mean(window**2))))


@contextmanager
def null_sinks():
    suffix = str(time.time_ns())
    names, modules = [], []
    try:
        for purpose in ('input', 'output'):
            name = 'hyf_' + purpose + '_' + suffix
            modules.append(pactl('load-module', 'module-null-sink', 'sink_name=' + name,
                                 'rate=48000', 'channels=2'))
            names.append(name)
        yield names
    finally:
        for module in reversed(modules):
            subprocess.run(['pactl', 'unload-module', module], capture_output=True)


@contextmanager
def synthetic_capture(inputs, source_sink):
    # Wine marks its stream node.dont-reconnect, so PulseAudio move-source-output
    # is refused. PipeWire's existing port-link API can route it without changing
    # the game's selected hardware device or the system default microphone.
    objects = json.loads(subprocess.check_output(['pw-dump'], text=True))
    nodes = {o['id']: o.get('info', {}).get('props', {}) for o in objects if o['type'].endswith(':Node')}
    ports = {o['id']: o.get('info', {}).get('props', {}) for o in objects if o['type'].endswith(':Port')}
    game_nodes = {int(s['properties']['object.id']) for s in inputs}
    source_nodes = {node for node, props in nodes.items() if props.get('node.name') == source_sink}
    monitors = {p.get('audio.channel'): port for port, p in ports.items()
                if int(p.get('node.id', -1)) in source_nodes and p.get('port.direction') == 'out'}
    targets = {port: p.get('audio.channel') for port, p in ports.items()
               if int(p.get('node.id', -1)) in game_nodes and p.get('port.direction') == 'in'}
    original, connected = [], []
    if not targets or not monitors:
        raise RuntimeError('Cannot find PipeWire capture ports for the synthetic microphone.')
    for obj in objects:
        if obj['type'].endswith(':Link'):
            props = obj.get('info', {}).get('props', {})
            pair = (int(props.get('link.output.port', -1)), int(props.get('link.input.port', -1)))
            if pair[1] in targets:
                original.append(pair)
    try:
        for out_port, in_port in original:
            subprocess.run(['pw-link', '-d', str(out_port), str(in_port)], check=True)
        for in_port, channel in targets.items():
            if channel not in monitors:
                raise RuntimeError('Synthetic microphone channel is unavailable: ' + str(channel))
            pair = (monitors[channel], in_port)
            subprocess.run(['pw-link', *map(str, pair)], check=True)
            connected.append(pair)
        yield
    finally:
        for pair in connected:
            subprocess.run(['pw-link', '-d', *map(str, pair)], capture_output=True)
        for pair in original:
            subprocess.run(['pw-link', *map(str, pair)], capture_output=True)


def measure(source_sink, capture_sink, amplitude):
    with tempfile.TemporaryDirectory(prefix='hyf-tone-') as directory:
        directory = Path(directory)
        signal = amplitude * np.sin(2 * np.pi * FREQUENCY * np.arange(RATE * 3) / RATE)
        with wave.open(str(directory / 'tone.wav'), 'wb') as audio:
            audio.setparams((2, 2, RATE, 0, 'NONE', 'not compressed'))
            audio.writeframes(np.repeat((signal * 32767).astype('<i2')[:, None], 2, axis=1).tobytes())
        with (directory / 'capture.raw').open('wb') as output:
            capture = subprocess.Popen(['parec', '--client-name=HearYourFriendsProbe', '--device=' + capture_sink + '.monitor',
                                        '--format=float32le', '--rate=48000', '--channels=2'],
                                       stdout=output, stderr=subprocess.PIPE)
            try:
                time.sleep(0.2)
                subprocess.run(['paplay', '--client-name=HearYourFriendsProbe', '--volume=65536',
                                '--device=' + source_sink, str(directory / 'tone.wav')],
                               check=True, timeout=8)
                time.sleep(0.2)
            finally:
                capture.terminate()
                capture.communicate(timeout=5)
        samples = np.fromfile(directory / 'capture.raw', dtype='<f4')
        samples = samples[:len(samples)//2*2]
        return tone_rms(samples)


def await_reload(log, offset, gain):
    deadline = time.monotonic() + 15
    marker = 'Loaded: gain=%.3f;' % gain if gain is not None else '[HearYourFriends] Loaded:'
    while time.monotonic() < deadline:
        text = log.read_text(errors='replace') if log.exists() else ''
        recent = text[offset:] if len(text) >= offset else text
        if marker in recent:
            return
        time.sleep(0.2)
    raise RuntimeError('UE4SS did not confirm a live reload. Check hot-reload settings and the game log.')


def validate_gain_sweep(results):
    baseline = next(item['tone_rms'] for item in results if item['gain'] == 1)
    noise = next((item['tone_rms'] for item in results if item['gain'] == 0), 0)
    if baseline < max(1e-7, noise * 10):
        raise RuntimeError('No test tone reached game output; this run is inconclusive.')
    failures = []
    for item in results:
        ratio = item['tone_rms'] / baseline
        item['ratio_to_1x'] = ratio
        if abs(ratio - item['gain']) > max(0.03, 0.2 * item['gain']):
            failures.append('%.2fx produced %.3fx' % (item['gain'], ratio))
    if failures:
        raise RuntimeError('Gain response failed: ' + '; '.join(failures))


def game_probe(args):
    # Check prerequisites before creating virtual devices or changing routing.
    outputs = streams('sink-inputs', args.process)
    inputs = streams('source-outputs', args.process)
    if not outputs or not inputs:
        raise RuntimeError('No game playback/capture stream found. Leave one world open with microphone loopback enabled.')
    config = mod_dir(args.game) / 'config.lua'
    original_config = config.read_bytes()
    log = mod_dir(args.game).parents[2] / 'UE4SS.log'
    results = []
    with null_sinks() as (test_input, test_output):
        try:
            for stream in outputs:
                pactl('move-sink-input', stream['index'], test_output)
            with synthetic_capture(inputs, test_input):
                for gain in (0, 0.1, 0.5, 1, 2, 4):
                    offset = len(log.read_text(errors='replace')) if log.exists() else 0
                    if configure(args.game, gain, diagnostics=True):
                        await_reload(log, offset, gain)
                    time.sleep(1)
                    rms = measure(test_input, test_output, args.amplitude)
                    results.append({'gain': gain, 'tone_rms': rms})
                    print(json.dumps(results[-1]), flush=True)
        finally:
            offset = len(log.read_text(errors='replace')) if log.exists() else 0
            try:
                if write_changed(config, original_config):
                    await_reload(log, offset, None)
                    time.sleep(0.75)  # Allow the first game-thread update before unmuting output.
            finally:
                for stream in outputs:
                    subprocess.run(['pactl', 'move-sink-input', str(stream['index']), str(stream['sink'])], capture_output=True)
    validate_gain_sweep(results)
    print(json.dumps(results, indent=2))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game', type=Path, default=DEFAULT_GAME)
    parser.add_argument('--process', default=r'Abiotic\s*Factor')
    parser.add_argument('--amplitude', type=float, default=0.01)
    parser.add_argument('--check-audio', action='store_true', help='Validate measurement through a virtual sink, without opening the game.')
    args = parser.parse_args()
    if not 0 < args.amplitude <= 0.05:
        parser.error('amplitude must be greater than zero and at most 0.05')
    try:
        if args.check_audio:
            with null_sinks() as (test_input, _):
                low = measure(test_input, test_input, args.amplitude)
                high = measure(test_input, test_input, 2 * args.amplitude)
                ratio = high / low if low else 0
                print(json.dumps({'low_rms': low, 'high_rms': high, 'measured_ratio': ratio}))
                if not 1.9 <= ratio <= 2.1:
                    raise RuntimeError('Audio measurement did not detect the expected twofold change.')
        else:
            game_probe(args)
    except (RuntimeError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + '\n')


if __name__ == '__main__':
    main()
