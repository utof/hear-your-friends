# Contributing

Run `python3 tools/check.py`. Requires Python 3, NumPy and Lua 5.4's shared library.
The Lua suites mock engine objects; the audio test measures actual game output.

```sh
python3 tools/audio_probe.py --check-audio  # No game required
python3 tools/dev.py --solo --diagnostics  # Deploy to an installed mod
python3 tools/dev.py --ui-fixture          # Five local UI preview rows; no network actors
python3 tools/audio_probe.py              # One loaded world with mic loopback
python3 tools/package.py                  # Manual-install ZIP
```

Use `--game /path/to/AbioticFactor` for another install. Enable
`EnableHotReloadSystem = 1` and `EnableAutoReloadingLuaMods = 1` under `[General]`
in `ue4ss/UE4SS-settings.ini`. Restart once after changing loader settings.
Later Lua edits reload in the running game; Ctrl+R is the manual fallback.

`state.lua` owns levels. `players.lua` binds player states to voice actors.
`playback.lua` applies native source DSP and preserves existing effects.
`slider.lua` extends ModMenu with USlider. `native_ui.lua` mounts controls in the
Players tab. `i18n.lua` follows Unreal’s active language; translation fixes are welcome.
`report.lua` produces diagnostics without player names, platform IDs,
recordings or full logs. `main.lua` connects these modules.

The game exposes `UniversalVoiceChat`, `PlayerVoiceChatActor` and
`MicrophoneSpeakComponent`. These are internal APIs and can change after updates.
Mute queries take world context before player state. Gain uses a source dynamics
preset with ratio 1 and zero look-ahead. Keep engine calls on the game thread.

Useful references: [UE4SS Lua API](https://docs.ue4ss.com/dev/lua-api),
[UMG sliders](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/UMG/USlider),
[source effects](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/USoundEffectSourcePresetChain).

Test mute, proximity/radio changes, reconnects and world changes with a second
client before claiming multiplayer support. Keep maintainer notes under `.local/`;
they are excluded from Git and release packages.

Run `tools/dev.py` without `--ui-fixture` to remove the preview. Preview sliders
use isolated test state; they do not verify multiplayer audio.
