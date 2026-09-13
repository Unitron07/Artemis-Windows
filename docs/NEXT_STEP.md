# Next implementation: M0A native Windows ARM64

Priority: immediate, before M1 identity/profiles/session features. The owner requested native ARM64 as a priority after accepting and merging the x64 baseline. Windows 11 x64 and native ARM64 are both intended for the first preview.

Track implementation and device evidence in [GitHub issue #3](https://github.com/Unitron07/Artemis-Windows/issues/3).

## Starting point

Start a new implementation branch from current `main`, which contains the history-preserving M0 merge (`cac41f124716aa67b1b16671a03588a480c9dfd0`). Preserve any newer main commits. [PR #1](https://github.com/Unitron07/Artemis-Windows/pull/1) is merged; [x64 CI](https://github.com/Unitron07/Artemis-Windows/actions/runs/34736992552) passed for both unmodified upstream and the candidate. The owner reported that the tested client works. See [BASELINE.md](BASELINE.md) for qualification gaps rather than assuming that test covered ARM64 or both host products.

The executable still identifies as Moonlight. M0A keeps this baseline while adding an ARM64 build of the existing application. Native ARM64 means an ARM64 client/runtime, without x64 emulation. It does not require a different Windows UI framework; x64-hosted cross-compilation is acceptable.

## Implementation scope

Steps 1 and 2 (build target selection and pinned dependencies) are implemented in the harness. Both archive checksums and dependency integrity guards were tested locally. Use separate x64/ARM64 checkouts to isolate upstream's shared dependency headers. Full ARM64 compilation has not yet been validated; the next task is ARM64 CI, followed by package and device verification.

| Area | Starting files | Required change |
| --- | --- | --- |
| Dependency inputs | `scripts/baseline-deps.json`, `scripts/setup-baseline-deps.ps1`, upstream `setup-deps.ps1` | Select x64 or ARM64 explicitly, pin the matching archive and checksum, inventory versions/licenses, and prevent mixing target dependencies |
| Build and evidence | `scripts/build-baseline.ps1`, upstream `scripts/build-arch.bat` | Select the correct target Qt kit/MSVC tools; make output and evidence paths architecture-specific; preserve x64 commands |
| Windows CI | `.github/workflows/build.yml`, `.github/workflows/build-windows-baseline.yml`, upstream reference `.github/workflows/build-win-mac.yml` | Build upstream then candidate for each architecture, with recursive submodules, pinned inputs and separate packages/symbols/evidence |
| Native package validation | Deployed executable, AntiHooking, Qt plugins, SDL and codec DLLs | Check PE machine types and reject x64 runtime files in the ARM64 package; keep host build tools separate |
| Documentation | `docs/BUILD_WINDOWS.md`, `docs/BASELINE.md`, `docs/VALIDATION.md` | Publish verified ARM64 commands, artifact links, compiler/SDK/dependency inputs and honest device results |

Reuse the upstream Qt 6.11.2 ARM64 cross kit and matching MSVC ARM64 tooling. Resolve compatibility using build evidence; do not infer compiler versions from the kit's `msvc2022` label. Keep architecture-specific dependency and output directories so sequential local builds cannot reuse the wrong runtime files.

## Acceptance criteria

- Fresh recursive checkouts build both unmodified upstream and the ARM64 candidate in Windows CI; x64 builds remain green.
- Portable ZIPs, symbols, source with pinned submodules, licenses, hashes, and toolchain/dependency evidence are separately identifiable by target architecture.
- A package check verifies ARM64 PE machine type for the client and all shipped native process-loaded DLLs, including Qt plugins; it rejects a deliberately introduced x64 DLL.
- The packaged executable starts natively on a recorded Windows 11 ARM64 device without development tools. Architecture evidence and actual decoder selection are captured.
- H.264 1080p60 SDR pairing/streaming with audio, keyboard, mouse and gamepad passes against recorded Sunshine and Apollo versions. Record available codec paths, sleep/resume, display/input behavior, and the soak test from [VALIDATION.md](VALIDATION.md).
- An ARM64 performance baseline uses unmodified ARM64 Moonlight on the same hardware and inputs. Missing hardware, host access, or untested codecs remain explicit open gates.

The next implementation deliverable is ARM64 CI using the target-aware harness. Do not mark M0A complete merely because CI passes; attach real-device results before claiming native ARM64 qualification. After M0A, begin M1 by isolating Artemis names, settings, pairing credentials, logs, update identity, and installer identifiers on both targets, then add profiles and session actions.
