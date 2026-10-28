# Hear Your Friends

Research toward a client-side voice-volume boost for Abiotic Factor. **This is not yet a working mod.** There is no slider, installable package, or verified way to boost a friend's voice here yet.

## What we know

- [Deep Field's modding FAQ](https://steamcommunity.com/app/427410/discussions/0/572675720491522460/) lists supported content, and says new gameplay settings and keybindings are not supported by the initial official tools. It also says unofficial mods are allowed. The FAQ predates release, so this is not proof of every current editor capability.
- The free [official Mod Editor](https://store.epicgames.com/p/abiotic-factor-mod-editor-3b7438) is a Windows application, and official mods use mod.io. [The developer's installation guide](https://steamcommunity.com/app/427410/announcements/) explains the in-game mod browser. An unofficial UE4SS mod would be separately installed on PC and would not be an official mod.io package.
- The installed Steam game (build `26232136`) includes debug symbols for `UniversalVoiceChatPro`. Those symbols expose the names `PlayerVoiceChatActor`, `MicrophoneSpeakComponent`, and `SetVoiceVolume(float)`. Debug information shows that `SetVoiceVolume` calls `SetVolumeMultiplier` through `UpdateVoiceVolume`, and that the replicated voice-volume notification also reaches that path. This is evidence of a possible playback control, not proof that applying gain on a client is correct or that gain above 1 works in game.
- [UE4SS Lua API](https://docs.ue4ss.com/lua-api.html) documents reflected object discovery and function hooks. [UE4SS GUI tabs](https://docs.ue4ss.com/guides/creating-gui-tabs-with-c++-mod.html) documents a C++ ImGui tab, not a built-in game settings slider. Availability and compatibility with this game build still need testing.
- [Community modding guide](https://hackmd.io/@Swept/abioticfactormodding) describes older unofficial workflows; its versions and mappings may be out of date after Community Update #5.

## Next steps

1. Inspect the current official editor and verify whether it exposes the voice system or any settings UI extension point.
2. With a compatible UE4SS installation, inspect live remote-player voice actors and establish which audio component carries incoming voice. Check the local player separately and do not alter the sender's microphone.
3. In a two-player session, test voice at gain 1 and greater than 1, while checking distance attenuation, radio effects, mute, player reconnects and replicated volume updates. Ensure repeated updates do not compound gain.
4. Only after that, implement a persistent client-side slider using a verified UI route, and package and test installation.

No game files or loader binaries are included in this repository.
