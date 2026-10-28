# Hear Your Friends

A PC UE4SS mod for **Abiotic Factor** that adjusts incoming voice playback from
**0–4×** through an **F8** settings menu. Zero mutes, 1 is normal, and 4 adds about
12 dB. The control is currently a numeric field. It applies to all incoming
players together. Source and bundled ModMenu dependency are MIT licensed.

**Experimental:** real in-game local loopback amplification is measured and
working on Steam build `26232136` with UE4SS `3.0.1-1176-g1ba38db4` under Proton.
Multiplayer voice selection, radio and reconnect behavior still need a real
second-client test. See [test evidence and development workflow](docs/testing.md).

## Install and use

1. Install a compatible UE4SS loader and the community
   [Abiotic Factor UE4SS configuration](https://github.com/igromanru/AF-UE4SS).
2. With the game closed, copy `Mods/HearYourFriends` into `ue4ss/Mods` and
   `Mods/shared/ModMenu` into `ue4ss/Mods/shared`. Keep the included MIT license.
   UE4SS's standard `shared/UEHelpers` must also be present. If ModMenu is already
   installed for another mod, check its version before replacing it.
3. Start the game, load a world, press **F8**, and enter a value from **0 to 4**.
   Settings reset to `Scripts/config.lua` defaults when the mod reloads.
4. To test alone, enable the game's microphone loopback and **Test local microphone
   playback** in F8. Use headphones. Turning the F8 checkbox off restores the local
   playback gain. This mod does not start capture or send voice to other players.

For a standard install, the loader lives under
`AbioticFactor/AbioticFactor/Binaries/Win64/ue4ss`. Loader layouts differ across
versions. Proton needs the loader's DLL override (`dwmapi=n,b` for the tested build).
The mod is designed for the listener's client; friends do not need it merely for
you to adjust their volume. That multiplayer behavior remains to be verified.

To remove it, close the game and remove `Mods/HearYourFriends`. Retain shared
libraries if another mod uses them. No game or loader binaries are redistributed.

## Why the first prototype did not work

Changing `MicrophoneSpeakComponent:SetVoiceVolume` changed its floating-point
readback, but positive values quickly reached an audible ceiling. Automated tone
measurements reproduced the zero-or-normal defect. Gain now uses Unreal's built-in
source dynamics processor with **ratio 1**, **zero look-ahead**, and an output gain
of `20 * log10(multiplier)`. It adds neither compression nor an intentional
monitoring delay. Device, game and codec buffering still add latency; no end-to-end
latency figure has been measured.

Private effect-chain copies preserve existing effects. The procedural sound and
the plugin's radio chain both retain the gain when the plugin changes its component
override. Replicated volume and the plugin's radio multiplier remain the baseline.
The mod attempts to respect local/global mutes and skip the local player unless
solo testing is enabled.

## Docs and exposed APIs

See [documentation map and API evidence](docs/apis.md) for official tools,
UE4SS, Unreal audio APIs, and the reflected voice objects found in the shipped game.
The [development guide](docs/testing.md) includes game-free regression tests,
measured audio tests without another player, and live deployment without relaunching.

## Publishing

The source is public at [utof/hear-your-friends](https://github.com/utof/hear-your-friends).
Package the two mod directories and licenses for a GitHub prerelease or a manual
Nexus upload, stating the exact tested loader/game build and remaining multiplayer
checks. A release package can be created with `python3 tools/package.py`.

This UE4SS Lua mod is **not** an official mod.io package. Deep Field's released
[Community Update #5 notes](https://steamcommunity.com/app/427410/discussions/7/569301136948069172/)
explicitly say unofficial mods remain outside the in-game browser and management
tools. To distribute through that browser, we need a separately validated official
Mod Editor implementation. Uploading this Lua ZIP there would not make it load.
Use [Nexus's submission guidelines](https://help.nexusmods.com/article/28-file-submission-guidelines)
for a functional, accurately described manual release; do the outstanding
multiplayer checks before presenting it as generally verified.
