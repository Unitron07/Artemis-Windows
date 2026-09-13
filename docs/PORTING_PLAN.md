# Porting plan

Updated after the M0 merge and the owner's request to prioritize native Windows ARM64. Completed integration items are checked below; build and test evidence lives in [BASELINE.md](BASELINE.md).

## Review outcome

The original choice to reuse Moonlight's Windows streaming stack is sound. The revised plan makes the fork decision explicit, removes a redundant new application shell, separates existing upstream features from porting work, and gives every milestone an observable completion gate.

**Chosen approach: extend the merged Moonlight PC fork, establish native Windows x64 and ARM64 baselines, then add missing Artemis features incrementally.** Preserve upstream history and layout. See [the feature audit](FEATURE_AUDIT.md) and [architecture](ARCHITECTURE.md).

## Scope and dependency order

M0 (integration merged) → **M0A (native ARM64, next priority)** → M1 → M2 → M3 → M4. M5 release qualification follows the included feature milestones. Server commands (M4) may be deferred from the first preview if their native protocol patch is not ready; document that omission. Clipboard (M3) depends on capability work in M2. M0A build delivery and ARM64 hardware qualification take priority over new desktop features. If hardware access blocks a test, record that blocker explicitly; a cross-build alone does not complete M0A.

Primary targets: **Windows 11 x64 and native ARM64**, both intended for the first preview. Native ARM64 means the client and its process-loaded runtime DLLs run as ARM64, without x64 emulation; cross-compiling on an x64 build host is acceptable. Windows 10 x64 remains a separate compatibility target pending runtime documentation and real-machine tests. Record exact minimum OS builds before publishing qualified binaries. These are support goals, not claims of completed ARM64 testing.

The first useful preview should preserve Sunshine streaming and add desktop profiles, clearer session actions, and opt-in Apollo text clipboard transfer. The wider roadmap adds virtual-display controls and host commands. Touch overlays, file transfer, simultaneous multiple streams, and a host companion service are outside the first release.

## M0 — Establish the Moonlight fork and reproducible baseline

**Status:** integration merged in [PR #1](https://github.com/Unitron07/Artemis-Windows/pull/1); x64 CI passed and the owner reported a successful manual test. Detailed qualification records remain outstanding as listed in the [baseline report](BASELINE.md).

- [x] Preserve the planning repository and Moonlight source history in a reviewed merge, retaining docs and resolving README/layout conflicts explicitly.
- [x] Record an `upstream` remote, baseline SHA, recursive submodule SHAs, source licenses, and imported-code provenance.
- [x] Build unmodified upstream first in Windows CI using its MSVC/Qt/qmake scripts. Capture compiler/SDK information, pinned Qt and dependency archive inputs, configuration, and commands in evidence artifacts.
- [x] Capture the existing source-based feature inventory.
- [ ] Capture measured performance baselines before branding or feature changes, and complete missing hardware/host-version records.
- [x] Adapt x64 Windows CI: recursive checkout, pinned actions and dependency checksums, build logs, executable artifacts, and symbols; ordinary builds use no release/signing credentials.

**Qualification gate (partly evidenced, carried forward):** a fresh checkout builds locally and in Windows CI; the deployed build launches on a clean test machine without developer tools; manually pair and stream 1080p60 H.264 SDR with audio, keyboard, mouse, and a gamepad. Record exact Sunshine and Apollo host versions and test each independently. Store results using [VALIDATION.md](VALIDATION.md). The owner's general test confirmation does not supply these individual records. A build-only VM does not establish hardware-decoder support.

**Deliverable:** baseline import PR, build instructions, CI artifact, and baseline report. No client feature rewrite is needed here.

## M0A — Native Windows ARM64 baseline (next priority)

- [ ] Extend the existing build harness to accept explicit x64/ARM64 targets. Keep the current x64 baseline working and preserve upstream source layout.
- [ ] Use the upstream Qt 6.11.2 ARM64 cross kit and matching MSVC ARM64 tools. Keep host-side Qt build tools distinct from deployed ARM64 runtime files.
- [ ] Pin and verify the v15 Windows ARM64 dependency archive, record its library versions, hashes, licenses, and source provenance, and isolate dependencies/output folders by target architecture.
- [ ] Build both unmodified upstream and the candidate for ARM64 in Windows CI. Keep x64 coverage; publish separate portable ZIPs, symbols, source, and compiler/SDK/dependency evidence for each architecture.
- [ ] Verify PE machine type for the client and every shipped native runtime DLL, including Qt plugins, SDL, codecs, and AntiHooking. Reject x64 DLL contamination in the ARM64 package. Build tools used on the host are outside this runtime check.
- [ ] Test the portable ARM64 build on a real Windows 11 ARM64 device without development tools: verify native process architecture, launch, discovery/manual host, pairing, H.264 1080p60 SDR, audio, keyboard, mouse, and gamepad with separately recorded Sunshine and Apollo hosts.
- [ ] Record hardware decoding and a performance baseline on that device against unmodified ARM64 Moonlight built with the same inputs. Test available additional codecs without claiming unsupported GPU paths.

**Exit gate:** reproducible ARM64 upstream/candidate builds and artifacts, native ARM64 runtime verification, real-device launch and streaming evidence, and passing x64 regression builds. Missing hardware or host access is an explicit open gate. An x64 binary under emulation does not satisfy the native ARM64 deliverable.

**Deliverable:** native ARM64 baseline PR and portable development build, per-architecture evidence, and hardware test report. See the implementation handoff in [NEXT_STEP.md](NEXT_STEP.md).

## M1 — Project identity and desktop workflow foundation

- [ ] Rename app/package identity and artwork as needed; preserve upstream attribution and licenses.
- [ ] Isolate settings, pairing identity, logs, and installer identifiers; verify side-by-side use with Moonlight.
- [ ] Add versioned global/host/app profiles around existing resolution, FPS, bitrate, codec, and input settings. Validate bounds and explain which changes require reconnecting.
- [ ] Add configurable session shortcuts and distinct actions for disconnecting the client, quitting the remote application, and closing the local app. Preserve a local capture-release shortcut.
- [ ] Extend existing diagnostics only for missing data; retain upstream stats and avoid adding per-frame logging.

**Exit gate on x64 and ARM64:** profiles survive restart and invalid data fails safely; settings/credentials remain isolated; 20 connect/disconnect cycles leave no stuck input or active extension tasks; disconnect leaves the host application running while an explicitly selected quit action has the documented host effect. M2–M4 changes also retain both architecture builds and run affected checks on each target.

## M2 — Pointer/scaling correctness and Apollo capability foundation

- [ ] Validate upstream direct/relative mouse modes, wheel input, keyboard layouts, focus behavior, and mixed-DPI monitor moves before changing them.
- [ ] Implement only verified gaps in fit/fill/stretch, pointer-mode switching, and session controls. Keep pan/zoom and touchpad overlays as later work unless a specific desktop requirement needs them.
- [ ] Parse authenticated host extension fields, permission bits, driver readiness, and command names; keep absence, denial, and transient failure distinct.
- [ ] Add fixtures for a standard host, Apollo with permissions, Apollo with denied permissions, malformed/missing fields, and changed capabilities after reconnect.

**Exit gate:** direct-pointer corner/center mapping stays correct under every implemented scaling mode, 100/150/200% DPI, and monitor switching; focus loss releases input. Sunshine works with extension fields absent and no unsolicited Apollo actions. A denied or failed extension does not stop the stream.

## M3 — Apollo text clipboard, then virtual-display requests

- [ ] Implement manual Send/Receive using the audited HTTPS contract and existing pairing trust. Add bounded requests, Unicode handling, echo suppression, cancellation, and explicit error states.
- [ ] Start with a proposed 1 MiB UTF-8 text limit and a 5-second request timeout; validate them during the spike. Limit response accumulation as well as outgoing data.
- [ ] Add automatic per-host synchronization only after manual behavior passes; default it off and document its triggers. Exclude file/image clipboard formats.
- [ ] Request Apollo virtual displays only after authenticated capability/readiness checks. Validate launch and resume separately; do not assume their behavior is identical.
- [ ] Exercise driver-missing, permission-denied, launch-failure, disconnect, client-crash, and reconnect cases. Document host-owned cleanup and recovery rather than attempting to restore the host's entire display configuration from the client.

**Exit gate:** plain text transfers both ways only with an active authorized session; failures preserve the local clipboard and do not leak content to another host. Unsupported responses, including an HTTP-200 error document, are not treated as clipboard text or successful writes. Apollo display requests succeed on the recorded host build or give an actionable reason; ordinary Sunshine launch remains unchanged.

## M4 — Apollo server commands

- [ ] Audit the Android JNI/native path against the chosen PC core and host revision. Implement a minimal native extension; preserve modern PC protocol fixes.
- [ ] Map host-advertised command names to their original indexes; enforce the native range and permissions, and handle missing/changed command lists.
- [ ] Add explicit action confirmation as described in the architecture. Do not retry commands automatically or present a transport send as confirmed execution.

**Exit gate:** a harmless configured command reaches the intended action on the test host, invalid/denied commands are blocked, reconnect does not replay actions, and standard Sunshine streaming still passes. Include packet/API tests for the native patch and record provenance.

## M5 — Qualify and release

- [ ] Compare the candidate to unmodified upstream using the same hardware, host, display mode, codec, network, and workload.
- [ ] Complete required [functional and performance checks](VALIDATION.md), including GPU-specific paths available for the claimed support matrix.
- [ ] Produce separate x64 and native ARM64 portable ZIPs for the first preview, with runtime dependencies, version information, hashes, symbols, notices, and corresponding source including pinned submodule contents. Publish exact build steps and known limitations for each architecture. Do not label an x64-emulated build as the ARM64 release.
- [ ] Validate ZIP data location, update, and clean-machine launch. Adapt upstream installer infrastructure after the portable preview is stable; test install/upgrade/uninstall and preservation of user data.
- [ ] Sign public stable executables/installers when release credentials are provisioned. Treat signing as a release gate, not a dependency for local development or clearly labeled unsigned previews.

**Exit gate:** all required checks for the advertised release scope pass, unsupported hardware/OS combinations are listed honestly, artifacts can be reproduced from the published inputs, and no unresolved regression defeats an included feature.

## Upstream maintenance

Keep feature PRs small and avoid mass renames of upstream source directories. Record upstream merge points and native-library patches. Check upstream changes before every release; prioritize security and correctness fixes, then rerun affected checks and the baseline streaming smoke test. Keep upstream platform code even when Windows is the only release target.

## Remaining decisions

- Exact Windows 11 ARM64 minimum build, device/SoC/GPU/driver, and qualification host access: resolve in M0A.
- Exact Windows 10 x64 minimum build and runtime support: resolve before advertising compatibility.
- Tested Sunshine/Apollo versions and the original manual test's client/host details: record during M0A; extension-specific support boundaries follow in M2.
- Overlay rendering approach: choose only after testing the existing video-window integration and latency impact.
- Touch-device qualification beyond the baseline keyboard/mouse/gamepad cases remains later work.

Do not attach calendar estimates until the ARM64 baseline and Apollo protocol spikes identify actual effort. The next concrete implementation task is M0A, followed by M1 identity and storage isolation.
