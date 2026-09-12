# Artemis Windows

An experimental native Windows client inspired by [Artemis Android](https://github.com/MobinYengejehi/Artemis).

The goal is to bring Artemis's office and remote-desktop-oriented improvements to Windows while retaining the low-latency streaming performance and hardware acceleration of [Moonlight PC](https://github.com/moonlight-stream/moonlight-qt).

> Status: planning and architecture stage. No working Windows client has been implemented yet.

## Project direction

Artemis Android is built around Android UI APIs, Android NDK integration, and `moonlight-common-c`. A direct APK-to-Windows conversion would not produce a good native application, so this project will port the relevant behavior into the Qt/QML + SDL architecture used by Moonlight PC.

## Initial goals

- Native Windows 10/11 client, starting with x64.
- Compatibility with Sunshine and Apollo hosts where practical.
- Low-latency hardware decoding through the existing Moonlight PC stack.
- Artemis-inspired controls for custom resolution, bitrate, scaling, shortcuts, clipboard, and remote-desktop workflows.
- First-class keyboard, mouse, gamepad, multi-monitor, and high-DPI support.
- Portable ZIP build first, followed by an installer once the client is stable.

## Planned architecture

```text
Qt/QML user interface
        |
Windows input, display, clipboard, and settings services
        |
Moonlight PC streaming/session layer
        |
moonlight-common-c + SDL2 + FFmpeg/hardware decode
        |
Sunshine / Apollo host
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/PORTING_PLAN.md](docs/PORTING_PLAN.md) for the working outline.

## Milestones

1. Audit Artemis Android and Moonlight PC feature differences.
2. Build an unmodified Moonlight PC baseline on Windows.
3. Add Artemis settings and remote-desktop features incrementally.
4. Add Apollo-specific integrations behind capability detection.
5. Benchmark latency, frame pacing, decoding, input, and multi-monitor behavior.
6. Produce signed portable and installer builds.

## Licensing

Artemis and Moonlight PC are GPLv3 projects. Any redistributed derivative work must preserve the applicable copyright notices, license terms, and corresponding source requirements. See the upstream repositories before distributing binaries.

## Contributing

This repository is intentionally only an outline for now. Implementation decisions should be recorded in issues or design notes before large feature work begins.
