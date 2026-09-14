# Artemis Windows

A Windows fork of [Moonlight PC](https://github.com/moonlight-stream/moonlight-qt), bringing over the useful desktop and office features of [Artemis Android](https://github.com/MobinYengejehi/Artemis).

> Status: M0 is merged and x64/ARM64 upstream and candidate CI builds passed after [PR #6](https://github.com/Unitron07/Artemis-Windows/pull/6)'s implementation. The harness now checks final portable ZIP binary architectures before upload. Native ARM64 device qualification remains the M0A priority; Artemis identity and features follow. See the [baseline report](docs/BASELINE.md) for evidence and open gates.

## Direction

**Establish native Windows x64 and ARM64 baselines, then add the Artemis features that Moonlight does not already provide.** Keep upstream's Qt/QML interface, SDL input/session code, hardware decoding, build scripts, and source layout. Port behavior from Android at the relevant boundary.

Moonlight already supplies much of the foundation, including custom resolution/frame-rate settings, direct mouse control, hardware decoding, HDR, and AV1. These are baseline features to preserve and test. See the [source audit and feature matrix](docs/FEATURE_AUDIT.md) for evidence and the remaining work.

## First release scope

- Windows 11 x64 and native ARM64 are first-preview targets. ARM64 build and hardware qualification are the immediate priority; Windows 10 x64 compatibility remains a separate, unverified target.
- Existing Sunshine streaming behavior, plus individually tested Apollo extensions.
- Desktop profiles, session shortcuts, clear disconnect/quit actions, and reliable pointer/scaling behavior.
- Opt-in plain-text clipboard transfer with Apollo, followed by host-managed virtual-display integration.
- Portable ZIP preview; installer and signing follow release validation.

Touch-overlay parity, simultaneous multi-stream viewing, and file transfer are later work. Existing upstream capabilities should remain intact.

## Plan

1. [Porting plan](docs/PORTING_PLAN.md): implementation order, dependencies, and completion criteria.
2. [Architecture](docs/ARCHITECTURE.md): upstream integration points and ownership boundaries.
3. [Feature audit](docs/FEATURE_AUDIT.md): pinned sources, existing features, and Apollo protocol findings.
4. [Validation plan](docs/VALIDATION.md): functional, compatibility, performance, and release checks.

Continue [M0A: native Windows ARM64](docs/NEXT_STEP.md). The [Windows build harness](docs/BUILD_WINDOWS.md) builds both targets with pinned dependencies and checks every EXE/DLL in the final ZIP, including nested Qt plugins. The new package gate has local guard-test coverage; hosted validation of this change and real-device qualification remain open. The [baseline report](docs/BASELINE.md) records successful build CI and the owner's earlier x64 test confirmation. The [upstream README](docs/MOONLIGHT_README.md) is preserved separately.

## Licensing and maintenance

The reviewed Artemis and Moonlight repositories include GPLv3 license texts. Preserve their applicable notices and licensing when importing code; ship the corresponding source and dependency/license information with releases. See the [upstream Moonlight license](https://github.com/moonlight-stream/moonlight-qt/blob/e3fd29e4d7dc5723d8d0da7d19e2698daec74456/LICENSE).

Keep Artemis changes small and isolated so upstream maintenance and security fixes can be integrated regularly. This project is an independent derivative and should use its own application, settings, pairing, and package identity.
