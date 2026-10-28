# Documentation and exposed APIs

## Official mod support

- [Community Update #5 released patch notes](https://steamcommunity.com/app/427410/discussions/7/569301136948069172/): mod.io browser, official local-only content, server mod downloads, and the explicit limitation that unofficial mods are not managed by that browser.
- [Deep Field modding FAQ](https://steamcommunity.com/app/427410/discussions/0/572675720491522460/): initial official editor scope includes content creation; new gameplay settings/keybindings were outside its stated initial scope. It predates release and is not exhaustive current editor documentation.
- [Official Abiotic Factor Mod Editor](https://store.epicgames.com/p/abiotic-factor-mod-editor-3b7438): free Windows editor distributed through Epic.
- [Abiotic Factor on mod.io](https://mod.io/g/abiotic-factor): official distribution target, requiring an implementation built and validated for that system.
- [Community UE4SS config](https://github.com/igromanru/AF-UE4SS): the loader/configuration used in this test. [Older community modding guide](https://hackmd.io/@Swept/abioticfactormodding) provides background; mappings can be outdated after CU5.

A bounded search by a GPT-6.1 Terra research subagent found no verified existing
incoming-player voice amplifier in mod.io, Nexus or GitHub results. This is not an
exhaustive absence claim. Audio asset replacement mods are a different capability.

## UE4SS and UI

- [Lua API](https://docs.ue4ss.com/dev/lua-api): reflected object access, `StaticFindObject`, `FindAllOf`, `StaticConstructObject`, `FindObject`, and `ModRef` shared values.
- [Creating a Lua mod](https://docs.ue4ss.com/dev/guides/creating-a-lua-mod): loader and script layout, reload workflow.
- [UStruct reflection](https://docs.ue4ss.com/dev/lua-api/classes/ustruct.html): enumerate reflected properties and functions.
- [ModMenu upstream](https://github.com/mattdavida/ue4ss-ModMenu), bundled revision `aff9716695f5432441cb329a9615721cc26a0d57`: F8 shell, numeric field and checkbox, shared input restoration. Upstream has no slider widget in this revision. The generated MIT bundle is unchanged. Our small reload adapter reuses its existing `core.shared` and `core.inputmode` modules; it stores a string instance tag rather than a world-object reference.

## Voice plugin in the shipped game

Steam build `26232136` ships UniversalVoiceChatPro native debug symbols. Runtime
reflection and local playback were checked under Unreal Engine **5.4.4**.
These are game/plugin internals, not an official Deep Field stable modding contract.

| Object / member | Purpose and evidence |
| --- | --- |
| `/Script/UniversalVoiceChatPro.Default__UniversalVoiceChat` | Reflected voice API singleton, found in the running world |
| `VoiceChatGetMyLocalPlayerVoiceChat()` | Local voice actor; exercised in the live test |
| `VoiceChatGetMuteAllPlayers()` | Reflected global mute query; selection behavior covered by mocks |
| `VoiceChatLocalIsMutedSomeone(WorldContextObject, playerToCheckMute)` | Per-player mute query; parameter order verified from shipped generated symbols |
| `PlayerVoiceChatActor.microphoneSpeakComponent` | Player's voice playback component |
| `PlayerVoiceChatActor.ownerPlayerState` | Identifies a remote player for mute checks |
| `PlayerVoiceChatActor.voiceVolume` | Replicated baseline; 8 in the tested local world |
| `MicrophoneSpeakComponent.VoiceCaptureAudioComponent` | Actual `UAudioComponent` used by the loopback test |
| `MicrophoneSpeakComponent.soundEffectChainAsset` | Plugin's radio effect-chain reference; readable through runtime reflection |
| `MicrophoneSpeakComponent:SetVoiceVolume(float)` | Native float API leading to `UAudioComponent::SetVolumeMultiplier`; stored values change, but this alone did not produce linear output |
| `payloadReceivedVoiceData`, `RPCReceiveVoiceFromServer`, `startSpeaking`, `endSpeaking` | Generated UFunction symbols exist; not used to inject packets or transmit synthetic speech |

The native `UpdateRadioState` chooses the radio effect chain or clears the component
override for proximity playback. The mod preserves gain in private copies of both
relevant sound chains. It does not write native offsets, patch executable code,
change replicated voice volume, or call voice-transmission APIs.

## Existing engine gain capability

- [UAudioComponent](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UAudioComponent): `VolumeMultiplier`, `SourceEffectChain`, `Sound`, and playback methods.
- [USoundBase](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/USoundBase): fallback `SourceEffectChain`.
- [USoundEffectSourcePresetChain](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/USoundEffectSourcePresetChain): chain entries and engine object references.
- [Source dynamics processor preset](https://dev.epicgames.com/documentation/unreal-engine/API/Plugins/Synthesis/SourceEffects/USourceEffectDynamicsProcessorPr-?application_version=5.5): `SetSettings` updates live DSP instances.
- [Dynamics settings](https://dev.epicgames.com/documentation/unreal-engine/API/Plugins/Synthesis/FSourceEffectDynamicsProcessorSe-): output gain, ratio, look-ahead. Current docs include fields absent in 5.4 (for example `bBypass` on the settings struct); only fields confirmed in this game's build are used.

The executed comparison is in [testing.md](testing.md): the component-volume API
failed the real gain sweep, while the existing dynamics effect passed. No custom
DSP, packet encoder, voice server, or reload service was needed. UE 5.4 exposes the
chain property but not a reflected live chain setter; installing a private chain
restarts that component once. Changing gain afterward uses `SetSettings` without
restarting playback. The preset is held by the chain's real `Chain` property;
adding only a runtime override left no engine reference for garbage collection.
