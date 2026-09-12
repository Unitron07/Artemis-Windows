# Porting plan

## Phase 0 — Baseline audit

- Pin the Artemis Android and Moonlight PC revisions used for comparison.
- Record the exact Artemis/Apollo protocol additions.
- Identify Android-only code paths versus portable protocol/native code.
- Build the upstream Moonlight PC client on Windows and capture baseline measurements.

## Phase 1 — Windows shell

- Establish the Qt/QML application shell and Windows packaging.
- Add a project-specific application identity and legal notices.
- Confirm host discovery, pairing, session startup, video, audio, keyboard, mouse, and gamepad input.
- Add a diagnostic page for decoder, renderer, network, and frame-pacing information.

## Phase 2 — Artemis workflow features

- Custom resolution, bitrate, scaling, and framerate presets.
- Configurable session shortcuts and a reliable quit/back-session flow.
- Clipboard synchronization where supported by the host.
- Improved pointer modes for remote desktop and office usage.
- Multi-monitor and fullscreen behavior.

## Phase 3 — Apollo integrations

- Capability negotiation for Apollo extensions.
- Virtual-display lifecycle and display-profile restoration.
- Server command UI with clear confirmation for disruptive actions.
- Host-side compatibility tests and fallback behavior.

## Phase 4 — Optimization and release

- Measure input-to-photon latency and frame pacing on NVIDIA, AMD, and Intel GPUs.
- Validate H.264, HEVC, AV1, HDR, high refresh rate, and multi-monitor cases.
- Test gamepads, keyboard layouts, high-DPI scaling, sleep/resume, and network changes.
- Produce portable ZIP and installer artifacts.
- Publish build instructions, third-party notices, and corresponding source information.

## Initial non-goals

- Recreating Android-specific navigation or touch UX one-for-one.
- Supporting every Linux/macOS target in the first milestone.
- Bundling or modifying the Apollo host in this client repository.
- Claiming feature parity before protocol and performance tests pass.

## Open decisions

- Whether the first implementation should live as a Moonlight PC fork or as a separate client sharing selected components.
- Which Apollo extensions are stable enough to expose by default.
- Whether virtual-display management belongs in the client, the host, or a companion Windows service.
- Minimum supported Windows version and ARM64 support timeline.
