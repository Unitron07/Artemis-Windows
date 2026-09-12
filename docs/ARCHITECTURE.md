# Architecture

## Decision: extend a Moonlight PC fork

Use Moonlight PC as the application, retaining its source history and layout. Do not build a second Windows shell or extract its streaming internals into a new framework for the first release. This follows the project owner's September 12, 2026 direction.

The [audit](FEATURE_AUDIT.md) pins the reviewed code. The implementation baseline must pass M0 before that revision, or a documented alternative, becomes the supported build baseline.

## Integration points

| Area | Existing Moonlight location | Planned change |
| --- | --- | --- |
| UI | `app/gui/` | Extend existing settings and session actions; use keyboard-accessible controls |
| Settings | `app/settings/streamingpreferences.*` | Versioned profiles and validated Artemis settings |
| Discovery, pairing, host HTTP | `app/backend/nvcomputer.*`, `nvhttp.*` | Parse Apollo fields and add a bounded authenticated clipboard request path |
| Session lifecycle | `app/streaming/session.cpp` | Attach extension services to the existing session |
| Input | `app/streaming/input/` | Extend existing capture, direct-pointer, and shortcut paths |
| Decode/render | Existing `app/streaming/` implementation | Preserve; modify only for a demonstrated feature gap |
| Native protocol | `moonlight-common-c/moonlight-common-c/` | Keep the upstream pin initially; later add a minimal reviewed server-command extension |
| Build/package | `moonlight-qt.pro`, `app/app.pro`, `scripts/`, `wix/` | Adapt upstream identity and packaging incrementally |

New extension classes belong beside the existing backend/session code. Class names and exact filenames can be chosen during implementation; these are responsibilities, not a demand for a new service framework.

## Responsibilities and boundaries

**Host capabilities:** maintain a per-host snapshot of supported, unsupported, and unknown extension states; permission bits; driver readiness; and the advertised command list. Refresh through the paired HTTPS path before launch/resume and after reconnect. Missing permission fields do not disable ordinary Sunshine streaming, but must not grant extension access. Parse permission values as an unsigned bitmask; preserve unknown bits without enabling unknown actions.

**Clipboard:** use paired HTTPS and plain text only initially. Expose Send and Receive first; automatic synchronization is an explicit per-host option added after correctness tests. Bound payloads and request time, suppress echo loops, and stop pending work on disconnect or host switch. Qt clipboard access stays on the GUI thread; network work must not block the GUI, input, decode, or render loops. Apply a completed response only if it still belongs to the active session. Clipboard contents, pairing secrets, and private keys must not appear in logs.

**Host display requests:** send verified Apollo launch/resume parameters. Apollo owns its virtual-display driver, host monitor creation, mode changes, and host cleanup. The client owns local window placement, monitor selection, and only local state it actually changed. A companion driver/service is out of scope. Requested stream dimensions, local render scaling, and the host desktop mode are separate settings; changing one does not prove the others changed. Do not promise live host resolution changes until supported and tested.

**Server commands:** show the host-advertised names and send only their validated index through the native control channel. Preserve original list order even if the UI sorts labels; reject indexes outside the supported range. Refresh the list before presenting actions, and do not replay a command after reconnect or timeout. A successful send is not proof of host execution. Do not introduce arbitrary shell-text execution. Confirm actions explicitly marked disruptive; if the host supplies no usable safety classification, confirm each command.

**Input and presentation:** retain upstream SDL routing rather than running a competing XInput/raw-input pipeline. Session shortcut configuration needs conflict detection and a reliable local capture-release action. Release pressed keys/buttons on focus loss and disconnect. Fit/fill/stretch or pan/zoom changes must share a coordinate transform with direct-pointer mapping. Prefer the existing rendering path; prototype and benchmark any overlay integration before depending on a QML overlay over the video window.

**Settings and identity:** give Artemis its own app name/ID, data directory, certificates, host IDs, package identifiers, and uninstall behavior. Test coexistence with Moonlight. Do not silently copy pairing credentials. Profiles use stable host/app identifiers and explicit precedence: global defaults, host profile, app override, session-only override. Version the schema and preserve recoverable settings when migration fails. Verify whether upstream portable mode meets the intended data-location contract before promising a self-contained ZIP.

## Dependency policy

Keep the pinned upstream Qt/MSVC/qmake and dependency workflow for the baseline. Do not add a CMake, SDL major-version, decoder, or framework migration to the port. Record actual compiler/SDK/runtime versions, submodule SHAs, dependency archive hashes, and build commands.

The reviewed Android repository uses a different `moonlight-common-c` fork. Do not replace the newer PC core wholesale with that older snapshot. Review the minimal required native change, its exported API and wire behavior, and test it against standard hosts. Record its provenance and maintain it as a small, separately reviewable patch set.

## Session lifecycle

Extension work follows the existing session: disconnected → connecting → streaming → stopping → disconnected. Cancel requests and discard stale responses when the session generation changes. Network failure, focus loss, sleep/resume, and application shutdown must converge on the same cleanup behavior.

A failed optional extension reports a useful status and leaves ordinary streaming usable. Do not silently terminate a running host application, retry a side-effecting command, or overwrite unrelated display state as a recovery step.
