# Asteria

**Asteria** is a native Windows game-streaming client based on [Moonlight PC](https://github.com/moonlight-stream/moonlight-qt), with enhanced integration planned for [Apollo](https://github.com/ClassicOldSong/Apollo) hosts and selected desktop/workflow ideas inspired by [Artemis Android](https://github.com/MobinYengejehi/Artemis).

> **Status:** the x64 and native ARM64 build baselines are established. PR #8 fixed the ARM64 portable-package CRT contamination exposed by the strict architecture gate. Real Windows 11 ARM64 device qualification remains the final M0A gate. The product identity is now moving from the upstream Moonlight identity to **Asteria**.

## Direction

Asteria keeps Moonlight PC's mature Qt/QML UI, SDL input/session stack, hardware decoding paths, build structure, and upstream history. New behavior is added at narrow integration boundaries so Moonlight security/correctness updates can continue to be merged without a giant permanent fork.

Moonlight already provides discovery, pairing, streaming, custom resolution/frame-rate controls, direct mouse input, hardware decoding, HDR, AV1, gamepad support, and performance statistics. Asteria should preserve those strengths while adding a Windows-focused identity, profiles and session workflows, measured frame-pacing improvements, and Apollo extensions.

## First preview scope

- Windows 11 x64 and **native ARM64**.
- Existing Sunshine compatibility plus individually tested Apollo extensions.
- Asteria-specific settings, pairing identity, logs, package/install identity, and side-by-side coexistence with Moonlight.
- Desktop profiles, clearer session actions and configurable shortcuts.
- Measurement-driven Windows frame-pacing/latency work.
- Opt-in plain-text clipboard transfer with Apollo, followed by host-managed virtual-display integration.
- Portable ZIP preview first; installer/signing follow release validation.

Touch-overlay parity, simultaneous multi-stream viewing, and file transfer are later work.

## Roadmap

1. **M0 — baseline import:** merged.
2. **M0A — native Windows ARM64:** build/CI/package architecture work is implemented; real-device qualification remains.
3. **M1 — Asteria identity and desktop workflow:** isolate product/settings/pairing/package identity, then profiles and session actions.
4. **M1A — Windows performance/frame pacing:** instrument and benchmark before changing defaults.
5. **M2 — pointer/scaling correctness and Apollo capability parsing.**
6. **M3 — Apollo text clipboard and virtual-display requests.**
7. **M4 — Apollo server commands.**
8. **M5 — release qualification.**

See the detailed [porting plan](docs/PORTING_PLAN.md), [architecture](docs/ARCHITECTURE.md), [feature audit](docs/FEATURE_AUDIT.md), [Windows build guide](docs/BUILD_WINDOWS.md), and [validation plan](docs/VALIDATION.md).

## Naming and provenance

**Asteria** is the application/product name. The intended repository name is **Asteria-Windows**.

The source remains a derivative of Moonlight PC and retains upstream history, licenses, source notices, submodules, and attribution. `docs/MOONLIGHT_README.md` preserves the upstream README. References to Artemis in the audit and roadmap refer to the separate Android project used as a behavioral reference; Asteria is an independent Windows client.

## Licensing and maintenance

The reviewed Moonlight and Artemis sources include GPLv3 licensing. Preserve all applicable notices and corresponding-source obligations when publishing builds. Keep Asteria changes small and isolated so upstream Moonlight security and correctness fixes can be integrated regularly.
