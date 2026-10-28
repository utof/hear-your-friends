# Hear Your Friends

An **experimental, unverified** PC UE4SS mod for Abiotic Factor that attempts to boost incoming voice chat. It has not yet been tested in the game or against a second player. It is not an official mod.io mod, and it currently uses a numeric field rather than a slider.

## Try the prototype

1. Install a UE4SS build compatible with your Abiotic Factor version. The community's [Abiotic Factor UE4SS configuration](https://github.com/igromanru/AF-UE4SS) and [Nexus page](https://www.nexusmods.com/abioticfactor/mods/35) are starting points, but compatibility with Community Update #5 has **not** been verified. The game developers warn that many older unofficial mods may break after that update.
2. With the game closed, copy `Mods/HearYourFriends` from this repository into your UE4SS `Mods` folder. The folder needs `Scripts/main.lua` and `enabled.txt`.
3. Copy `Mods/shared/ModMenu` into your UE4SS `Mods/shared` folder. **If a ModMenu is already installed**, do not overwrite it blindly; this prototype was written against the version recorded below, and compatibility with other versions is unknown. UE4SS's `shared/UEHelpers` must also be present.
4. Start the game, join a friend, and press **F8**. Enter a multiplier in **Voice multiplier**: `1` means normal, `2` means a proposed twofold multiplier, and the maximum is `4`. The value resets to `1` when the mod reloads. It applies to all incoming voices, not separately to each friend.
5. Compare normal and boosted speech, then check mute, proximity, radio, and reconnecting. Stop testing if the behavior is wrong. To remove this prototype, close the game and remove `Mods/HearYourFriends`; leave any shared dependency in place if another mod uses it.

Depending on the UE4SS build, `Mods` may be under `AbioticFactor/Binaries/Win64/ue4ss/Mods` or `AbioticFactor/Binaries/Win64/Mods`. Under Proton, an appropriate DLL override may be needed; follow the instructions for the actual loader build.

## Test alone with microphone playback

The F8 menu has an experimental **Test local microphone playback** checkbox. With headphones on, load a solo world, enable the game’s microphone listening/test option in its audio settings, and verify that you can hear your own microphone before continuing. Turn on the checkbox and compare the sound at 1× and 2×. Turn the checkbox off to restore the local playback volume. The checkbox is off on startup; the mod does not start microphone capture or transmit your voice. The microphone test and whether it uses the same local audio component are **not yet verified** with this game build; if your voice is not audible or the multiplier has no effect, this test is inconclusive.

This tests local playback, not a simulated network client. It cannot establish that other players’ voices, radio effects, attenuation, reconnects, or replication work correctly; those still require a multiplayer test. Automated mocked tests simulate remote-player objects and exercise the gain and mute logic without a second player.

The prototype starts at 1 and makes no voice-volume changes until a higher value is selected. It attempts to skip the local player, players muted locally, and actors whose player identity cannot be established. It periodically reapplies the multiplier to the actor's original replicated volume rather than repeatedly multiplying the last output. **These behaviors are only tested with mocked objects**, not in Abiotic Factor. If the game cannot expose the expected voice API or player identity, the mod will skip updates. Check the UE4SS log for `[HearYourFriends]` errors.

## Existing capabilities and evidence

- [Deep Field's modding FAQ](https://steamcommunity.com/app/427410/discussions/0/572675720491522460/) lists content mods, says its initial official tools cannot add new gameplay settings or keybindings, and permits unofficial mods. It predates release, so it does not establish every current editor capability. The [official Mod Editor](https://store.epicgames.com/p/abiotic-factor-mod-editor-3b7438) is a free Windows application.
- The installed Steam game (build `26232136`) includes debug symbols for `UniversalVoiceChatPro`. Unreal-generated symbols identify `PlayerVoiceChatActor.microphoneSpeakComponent`, `PlayerVoiceChatActor.voiceVolume`, `MicrophoneSpeakComponent.VoiceCaptureAudioComponent`, and the mute and local-player functions used by the prototype. Native symbols show `SetVoiceVolume(float)` ultimately calls `SetVolumeMultiplier`; replicated volume updates also reach this path. Symbol information does not prove that it boosts incoming voice correctly or respects every in-game audio state.
- [UE4SS Lua API](https://docs.ue4ss.com/lua-api.html) provides reflected-object access and game-thread execution. [ModMenu](https://github.com/mattdavida/ue4ss-ModMenu), revision `aff9716695f5432441cb329a9615721cc26a0d57`, provides a ready-made numeric settings field, but does not currently provide a slider. The included generated bundle is MIT licensed; its license is alongside it. The bundle was built using the upstream `node tools/bundle.mjs` command. It and UE4SS have not been verified against this particular game update.
- [Community modding guide](https://hackmd.io/@Swept/abioticfactormodding) describes older unofficial workflows; its versions and mappings may be outdated after Community Update #5.

## Development

Run `lua tests/voice_spec.lua` from the repository root with Lua 5.4. The tests use mocked UE4SS/game objects and check remote-player selection, mute handling, gain calculation, solo-test behavior, and returning to the baseline. They cannot establish actual game, sound, loader or menu compatibility.

No game files or loader binaries are included.

## Publishing

The source is public on [GitHub](https://github.com/utof/hear-your-friends). For a PC UE4SS release, create an archive containing `Mods/HearYourFriends` and the bundled `Mods/shared/ModMenu` (including its MIT license), clearly state the UE4SS requirement and game compatibility, then create a draft on [Nexus Mods](https://www.nexusmods.com/games/abioticfactor). Nexus requires functional files and accurate descriptions; consult its [submission guidelines](https://help.nexusmods.com/article/28-file-submission-guidelines) before publishing. Complete real playback and multiplayer tests first.

This UE4SS Lua prototype is not an official Mod Editor package and is not automatically distributed through Abiotic Factor’s mod.io browser. Official mod.io distribution would require a separately validated implementation using the official mod tooling.
