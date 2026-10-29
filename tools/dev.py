#!/usr/bin/env python3
"""Deploy Lua sources; UE4SS's built-in watcher reloads the running mod."""
import argparse
from pathlib import Path
import os
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GAME = Path.home() / '.steam/steam/steamapps/common/AbioticFactor'


def mod_dir(game):
    return Path(game) / 'AbioticFactor/Binaries/Win64/ue4ss/Mods/HearYourFriends/Scripts'


def write_changed(path, data):
    if path.exists() and path.read_bytes() == data:
        return False
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as temp:
        temp.write(data)
        staged = temp.name
    os.replace(staged, path)
    return True


def configure(game, gain=1, solo=False, diagnostics=False):
    if not 0 <= gain <= 4:
        raise ValueError('gain must be between 0 and 4')
    destination = mod_dir(game)
    if not destination.is_dir():
        raise RuntimeError('Install UE4SS and HearYourFriends before deploying.')
    data = ('return { gain = %.9g, soloTest = %s, diagnostics = %s }\n' %
            (gain, str(solo).lower(), str(diagnostics).lower())).encode()
    return write_changed(destination / 'config.lua', data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game', type=Path, default=DEFAULT_GAME)
    parser.add_argument('--gain', type=float, default=1)
    parser.add_argument('--solo', action='store_true')
    parser.add_argument('--diagnostics', action='store_true')
    args = parser.parse_args()
    destination = mod_dir(args.game)
    if not destination.is_dir():
        parser.error('Installed HearYourFriends Scripts directory was not found.')
    sources = sorted((ROOT / 'Mods/HearYourFriends/Scripts').glob('*.lua'), key=lambda p: p.name == 'main.lua')
    changed = False
    for source in sources:
        if source.name == 'main.lua':
            changed |= configure(args.game, args.gain, args.solo, args.diagnostics)
        if source.name != 'config.lua':
            changed |= write_changed(destination / source.name, source.read_bytes())
    print('Deployed; UE4SS auto-reload will apply it.' if changed else 'Installed files already match.')
    print('Gain %.3f; solo %s; diagnostics %s.' % (args.gain, args.solo, args.diagnostics))


if __name__ == '__main__':
    main()
