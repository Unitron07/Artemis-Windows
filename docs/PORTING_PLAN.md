# Porting plan

Reviewed September 12, 2026. This is a plan, not a record of completed implementation.

## Review outcome

The original choice to reuse Moonlight's Windows streaming stack is sound. The revised plan makes the fork decision explicit, removes a redundant new application shell, separates existing upstream features from porting work, and gives every milestone an observable completion gate.

**Chosen approach: fork Moonlight PC, establish the Windows baseline, then add missing Artemis features incrementally.** Preserve upstream history and layout. See [the feature audit](FEATURE_AUDIT.md) and [architecture](ARCHITECTURE.md).

## Scope and dependency order

M0 → M1 → M2 → M3 → M4. M5 release qualification follows the included feature milestones. Server commands (M4) may be deferred from the first preview if their native protocol patch is not ready; document that omission. Clipboard (M3) depends on capability work in M2.

Primary target: Windows 11 x64. Windows 10 remains a compatibility target pending verification of the chosen Qt/runtime/OS combination and real-machine tests. Record an exact minimum build before publishing binaries. Retain upstream ARM64 support where present, but qualify and distribute ARM64 later. These are proposed support boundaries, not claims of tested compatibility.

The first useful preview should preserve Sunshine streaming and add desktop profiles, clearer session actions, and opt-in Apollo text clipboard transfer. The wider roadmap adds virtual-display controls and host commands. Touch overlays, file transfer, simultaneous multiple streams, and a host companion service are outside the first release.

## M0 — Establish the Moonlight fork and reproducible baseline

- [ ] Preserve the existing planning repository. Integrate Moonlight PC history into an implementation branch based on its upstream commit, then merge that work through a reviewed PR while retaining these docs. Resolve README/layout conflicts explicitly; no force-push over planning history. A GitHub fork relationship is optional metadata, not a reason to delete/recreate this repository.
- [ ] Record an `upstream` remote, baseline SHA, recursive submodule SHAs, source licenses, and imported-code provenance. The audit SHA is a comparison snapshot; choose it or a documented release revision after testing.
- [ ] Build unmodified upstream first, using its Windows MSVC/Qt/qmake scripts and dependency setup. Record compiler, Windows SDK, Qt, dependency archive versions/hashes, configuration, and exact commands.
- [ ] Capture the existing feature inventory and performance baseline before branding or feature changes.
- [ ] Adapt Windows CI from upstream: recursive checkout, pinned dependencies/actions where practical, build logs, executable artifacts, and symbols. Separate ordinary PR builds from credentialed release/signing jobs.

**Exit gate:** a fresh checkout builds locally and in Windows CI; the deployed build launches on a clean test machine without developer tools; manually pair and stream 1080p60 H.264 SDR with audio, keyboard, mouse, and a gamepad. Record exact Sunshine and Apollo host versions and test each independently. Store results using [VALIDATION.md](VALIDATION.md). A build-only VM does not establish hardware-decoder support.

**Deliverable:** baseline import PR, build instructions, CI artifact, and baseline report. No client feature rewrite is needed here.

## M1 — Project identity and desktop workflow foundation

- [ ] Rename app/package identity and artwork as needed; preserve upstream attribution and licenses.
- [ ] Isolate settings, pairing identity, logs, and installer identifiers; verify side-by-side use with Moonlight.
- [ ] Add versioned global/host/app profiles around existing resolution, FPS, bitrate, codec, and input settings. Validate bounds and explain which changes require reconnecting.
- [ ] Add configurable session shortcuts and distinct actions for disconnecting the client, quitting the remote application, and closing the local app. Preserve a local capture-release shortcut.
- [ ] Extend existing diagnostics only for missing data; retain upstream stats and avoid adding per-frame logging.

**Exit gate:** profiles survive restart and invalid data fails safely; settings/credentials remain isolated; 20 connect/disconnect cycles leave no stuck input or active extension tasks; disconnect leaves the host application running while an explicitly selected quit action has the documented host effect.

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
- [ ] Produce a portable ZIP with runtime dependencies, version information, hashes, symbols, notices, and corresponding source including pinned submodule contents. Publish exact build steps and known limitations.
- [ ] Validate ZIP data location, update, and clean-machine launch. Adapt upstream installer infrastructure after the portable preview is stable; test install/upgrade/uninstall and preservation of user data.
- [ ] Sign public stable executables/installers when release credentials are provisioned. Treat signing as a release gate, not a dependency for local development or clearly labeled unsigned previews.

**Exit gate:** all required checks for the advertised release scope pass, unsupported hardware/OS combinations are listed honestly, artifacts can be reproduced from the published inputs, and no unresolved regression defeats an included feature.

## Upstream maintenance

Keep feature PRs small and avoid mass renames of upstream source directories. Record upstream merge points and native-library patches. Check upstream changes before every release; prioritize security and correctness fixes, then rerun affected checks and the baseline streaming smoke test. Keep upstream platform code even when Windows is the only release target.

## Remaining decisions

- Exact Windows 10 minimum build and runtime support: resolve in M0 with dependency documentation and testing.
- Tested Sunshine/Apollo release versions and extension-specific support boundaries: resolve during M0/M2 and publish results.
- Overlay rendering approach: choose only after testing the existing video-window integration and latency impact.
- ARM64 and touch-device qualification hardware: decide after the x64 preview.

Do not attach calendar estimates until the baseline and Apollo protocol spikes identify actual effort. The next concrete implementation task is M0.
