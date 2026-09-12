# Architecture outline

## Guiding principle

Reuse the mature Windows streaming path from Moonlight PC wherever possible. Port Artemis behavior at the feature boundary instead of translating Android classes line by line.

## Proposed layers

### 1. Presentation layer

- Qt 6/QML desktop interface.
- Responsive layouts for desktop monitors and Windows handhelds.
- Settings pages for stream, input, display, host integrations, and diagnostics.
- In-session overlay for shortcuts, performance information, scaling, and session actions.

### 2. Windows platform layer

- Raw and captured mouse/keyboard input.
- XInput and SDL gamepad support, including force feedback and motion where available.
- Display enumeration, monitor selection, DPI awareness, fullscreen, borderless, and rotation behavior.
- Windows clipboard integration.
- Optional virtual-display coordination and display-profile restoration.
- Windows notifications, startup behavior, and application data storage.

### 3. Streaming/session layer

- Moonlight PC session lifecycle and host discovery.
- Stream negotiation, video/audio decode, rendering, and frame pacing.
- Capability detection for standard Sunshine versus Apollo extensions.
- Structured diagnostics for latency, decode path, network health, and dropped frames.

### 4. Shared protocol/native layer

- `moonlight-common-c` for the GameStream protocol foundation.
- SDL2 and the existing Moonlight PC input abstractions.
- FFmpeg and platform hardware-decoding integrations supplied by the upstream build.

## Feature mapping

| Artemis Android capability | Windows treatment |
| --- | --- |
| Custom resolution and bitrate | Native stream settings and presets |
| Mouse modes and virtual touchpad | Captured pointer, direct pointer, and optional touchpad overlay |
| Custom shortcuts | Configurable global/session shortcut system |
| Clipboard sync | Windows clipboard service, capability-gated by host |
| Virtual display integration | Windows display service, capability-gated by Apollo/host |
| Server commands | Host integration service with explicit user actions |
| Performance display | Desktop overlay and diagnostics page |
| Virtual buttons | Optional overlay for touch-enabled Windows devices |
| Android vibration fallback | Windows haptics/force-feedback routing |

## Compatibility policy

Standard Sunshine/Moonlight behavior should remain the default. Apollo-only features must be detected at runtime and degrade gracefully when the host does not advertise support.
