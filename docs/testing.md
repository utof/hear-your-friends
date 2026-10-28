# Testing and development

The game-independent suite runs with `python3 tools/check.py` (Python 3, NumPy,
and Lua 5.4's shared library). Alternatively run each `tests/*_spec.lua` with
`lua5.4` and `python3 -m unittest discover -s tests -p 'test_*.py'`. GitHub Actions
runs these checks on pushes and pull requests.

The Lua suites mock engine objects. They cover voice actor selection, mute checks,
restoring baseline volume, gain conversion, effect ownership and preservation,
radio/proximity chain switches, and cleaning up an open menu after a Lua reload.
They do **not** prove that real audio is amplified.

## Actual audio acceptance test

On Linux with PipeWire's PulseAudio compatibility server, `pactl`, `paplay`,
`parec`, `pw-dump`, `pw-link`, and NumPy:

```sh
python3 tools/audio_probe.py --check-audio
python3 tools/audio_probe.py
```

The first command needs no game. It plays two amplitudes through a temporary
virtual audio sink and checks that measured amplitude doubles. The second needs
**one running game instance in a loaded world with the game's microphone loopback
enabled**. No second player, listening judgment, game relaunch, or physical
microphone recording is required. This is a local playback test, not a network
client simulation.

The tool temporarily routes only the game's audio output to an isolated virtual
sink and feeds a quiet 997 Hz tone into its capture ports. It sweeps 0–4, waits for
UE4SS's reload confirmation, measures the tone band, and rejects a flat positive
gain response. It checks the signal against the zero-gain background floor.
It restores configuration and audio routing in `finally` blocks and removes the
virtual devices. No recording is retained. Default audio devices are untouched.
The stream matcher intentionally ignores window/media titles so an Abiotic Factor
page open in a browser is not treated as game audio.

This implementation uses existing PulseAudio/PipeWire tools. Proton's capture
stream rejected PulseAudio's `move-source-output` with `Invalid argument`; the
existing PipeWire port-link API worked and is used for capture routing instead.

## Live code updates

Tested loader: UE4SS `3.0.1-1176-g1ba38db4`, with the community
[AF-UE4SS configuration](https://github.com/igromanru/AF-UE4SS).
In `ue4ss/UE4SS-settings.ini`, enable:

```ini
[General]
EnableHotReloadSystem = 1
EnableAutoReloadingLuaMods = 1
HotReloadKey = R
```

These loader settings require one launch to take effect. After that:

```sh
python3 tools/dev.py --gain 1 --solo --diagnostics
```

This copies changed Lua sources and a test configuration to the installed mod.
UE4SS's own watcher reloads the mod; Ctrl+R is its manual fallback. There is no
custom watcher service. Reopen F8 after a reload. This mod removes its previous
panel and reuses ModMenu's existing input restoration, so an open panel does not
become an unresponsive copy. Values come from `Scripts/config.lua` on each reload;
F8 edits are session-only. Deploy normal startup defaults with:

```sh
python3 tools/dev.py
```

Use `--game '/path/to/AbioticFactor'` with either tool for another installation.
Check `[HearYourFriends] Loaded:` and errors in `ue4ss/UE4SS.log`; the deploy command
itself confirms file copying, while the audio probe also waits for a reload log.

## Evidence and remaining checks

On Steam build `26232136`, Unreal Engine `5.4.4`, Proton Experimental, the old
component-volume implementation reproduced the reported bug: relative output at
0.1, 0.5, 2 and 4 was 0.975, 0.995, 0.950 and 0.993. At smaller values (0.005–0.05),
output changed before reaching that ceiling. Float readbacks alone were misleading.
The virtual-device measurement self-check measured 2.002× for a doubled input.

The first source-effect implementation measured:

| Control | Measured output relative to 1× |
| --- | ---: |
| 0 | 0.012 (background sound) |
| 0.1 | 0.099 |
| 0.5 | 0.501 |
| 1 | 1.000 |
| 2 | 1.976 |
| 4 | 3.984 |

The final build also passed after clearing the component override, exercising the
procedural sound fallback. Measured ratios were 0.016 (background) at 0, 0.100 at
0.1, 0.505 at 0.5, 1.000 at 1, 1.952 at 2, and 3.929 at 4. The test restored the
original configuration and physical audio routes. Both measured runs use real
engine audio, not the mocked volume setter.

F8 was opened in the live world, showed the current 2× / +6.02 dB value, and was
removed on the next code reload. Reopening it created a working current panel.

Still required before a general player release: a second real client; individual
and global mute in multiplayer; proximity/radio transitions; join/reconnect;
leaving/reloading worlds; Windows compatibility; and coexistence with other audio
mods. The test cannot certify these from solo loopback. High gain can clip speech
that is already loud.
