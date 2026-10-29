# Hear Your Friends — voice chat volume for Abiotic Factor

Hear quiet friends louder without raising every game sound. Adjust proximity chat
and voice chat volume with a master slider and individual player volume controls.

- Follows the game’s language setting in all nine supported languages.
- Sliders range from 0–4×. Master and player levels multiply.
- Native controls appear in **Escape → Manage Players → Players**. **F8** opens a separate panel.
- **Report a bug** saves diagnostics and opens a GitHub issue draft. Review it before submitting.
- Microphone playback lets you test alone. Enable the game's microphone loopback first.

## Install

1. Install [UE4SS with the Abiotic Factor configuration](https://github.com/igromanru/AF-UE4SS).
2. Copy this release's `Mods/HearYourFriends` and `Mods/shared/ModMenu` into the matching UE4SS folders. Keep UE4SS's standard `shared/UEHelpers`.
3. Load a world. Open **Manage Players** or press **F8**.

This PC build uses UE4SS and manual installation. It is not yet an official mod.io
package. Tested loader: `3.0.1-1176-g1ba38db4`; Steam build: `26232136`, under Proton.
Multiplayer, radio transitions and Windows still need tests.

Designed to run on the listener’s PC; listener-only multiplayer installation still
needs a second-client test. Player levels apply to the current world session.
Close the game and remove `Mods/HearYourFriends` to uninstall. Keep shared libraries
if another mod uses them.

[Report an issue](https://github.com/utof/hear-your-friends/issues) ·
[Contribute](CONTRIBUTING.md) · **[Support development on Ko-fi](https://ko-fi.com/utof)**

MIT license. Includes [ModMenu](https://github.com/mattdavida/ue4ss-ModMenu), also MIT.
