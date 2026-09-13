# Artemis Windows

A planned Windows fork of [Moonlight PC](https://github.com/moonlight-stream/moonlight-qt), bringing over the useful desktop and office features of [Artemis Android](https://github.com/MobinYengejehi/Artemis).

> Status: M0 baseline import under validation. Moonlight source and history are imported; Artemis features and independent application identity are not implemented. Hardware streaming and clean-machine qualification remain pending.

## Direction

**Fork Moonlight PC first, establish a working Windows baseline, then add the Artemis features that Moonlight does not already provide.** Keep upstream's Qt/QML interface, SDL input/session code, hardware decoding, build scripts, and source layout. Port behavior from Android at the relevant boundary.

Moonlight already supplies much of the foundation, including custom resolution/frame-rate settings, direct mouse control, hardware decoding, HDR, and AV1. These are baseline features to preserve and test. See the [source audit and feature matrix](docs/FEATURE_AUDIT.md) for evidence and the remaining work.

## First release scope

- Windows x64, with Windows 11 as the primary validation target; exact Windows 10 compatibility is a baseline-build gate.
- Existing Sunshine streaming behavior, plus individually tested Apollo extensions.
- Desktop profiles, session shortcuts, clear disconnect/quit actions, and reliable pointer/scaling behavior.
- Opt-in plain-text clipboard transfer with Apollo, followed by host-managed virtual-display integration.
- Portable ZIP preview; installer and signing follow release validation.

Touch-overlay parity, ARM64 release qualification, simultaneous multi-stream viewing, and file transfer are later work. Existing upstream capabilities should remain intact.

## Plan

1. [Porting plan](docs/PORTING_PLAN.md): implementation order, dependencies, and completion criteria.
2. [Architecture](docs/ARCHITECTURE.md): upstream integration points and ownership boundaries.
3. [Feature audit](docs/FEATURE_AUDIT.md): pinned sources, existing features, and Apollo protocol findings.
4. [Validation plan](docs/VALIDATION.md): functional, compatibility, performance, and release checks.

Start with the [Windows build instructions](docs/BUILD_WINDOWS.md) and [M0 baseline report](docs/BASELINE.md). The [upstream README](docs/MOONLIGHT_README.md) is preserved separately. CI builds unmodified upstream before the candidate and uploads unsigned portable packages, symbols, and evidence. M0 remains open until its build and real-machine gates pass.

## Licensing and maintenance

The reviewed Artemis and Moonlight repositories include GPLv3 license texts. Preserve their applicable notices and licensing when importing code; ship the corresponding source and dependency/license information with releases. See the [upstream Moonlight license](https://github.com/moonlight-stream/moonlight-qt/blob/e3fd29e4d7dc5723d8d0da7d19e2698daec74456/LICENSE).

Keep Artemis changes small and isolated so upstream maintenance and security fixes can be integrated regularly. This project is an independent derivative and should use its own application, settings, pairing, and package identity.
