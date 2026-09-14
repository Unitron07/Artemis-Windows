# M0 baseline report and provenance

M0 baseline integration is **merged and accepted as the starting point for further development**. Both Windows x64 CI builds passed and the project owner confirmed that the tested client works. Detailed hardware and interoperability qualification is not yet fully recorded. Asteria identity and x64/ARM64 CI packaging are now implemented; the next priority is [real Windows 11 ARM64 qualification](NEXT_STEP.md). Historical M0 observations below retain their original scope.

## Imported history

- Planning parent: `Unitron07/Artemis-Windows` at `062306920ffb8b7bec9d07b6eb119401e035a1ea`.
- Upstream: `https://github.com/moonlight-stream/moonlight-qt.git` at `e3fd29e4d7dc5723d8d0da7d19e2698daec74456`.
- Integration branch: `codex/m0-moonlight-baseline`. [PR #1](https://github.com/Unitron07/Asteria-Windows/pull/1) merged into `main` as `cac41f124716aa67b1b16671a03588a480c9dfd0`, retaining both planning and Moonlight ancestries.
- The audit snapshot is now the imported development baseline. This does not establish a fully qualified release support matrix. No Android or Apollo implementation is imported.
- Artemis README is retained; the upstream README is preserved as `MOONLIGHT_README.md`. Ignore rules are combined and the obsolete `src/README.md` placeholder is removed. Upstream source directories, platform code, build scripts, licenses, and native gitlinks are preserved.

## Recursive submodules

| Path | Revision | Source |
| --- | --- | --- |
| `app/SDL_GameControllerDB` | `8d9fefd7b810f2541f78cc7a8ccbd185bc84c7a5` | gabomdq/SDL_GameControllerDB |
| `moonlight-common-c/moonlight-common-c` | `62e066388f1a1b133e0bee947b9a374311a3354b` | moonlight-stream/moonlight-common-c |
| `moonlight-common-c/moonlight-common-c/enet` | `aca87840b57f045a1f7f9299e4b1b9b8e2a5e2f1` | cgutman/enet |
| `moonlight-common-c/moonlight-common-c/nanors` | `b1e3c22ca0cdc0bb83e3cd6ed1a2fc77869ed99a` | sleepybishop/nanors |
| `qmdnsengine/qmdnsengine` | `920c097ffa742e2968290f15d4dde6693aec02e5` | cgutman/qmdnsengine |

## Licenses and dependencies

Retain root GPLv3 `LICENSE`, `moonlight-common-c/moonlight-common-c/LICENSE.txt` (GPLv3), `h264bitstream/LICENSE` (LGPL 2.1), qmdnsengine's MIT license, enet's license, nanors' MIT license, SDL_GameControllerDB's license, and all per-file notices. Imported source is attributable through the full Git history. Consult the actual license texts for terms.

The Windows x64 archive comes from [Moonlight dependencies v15](https://github.com/moonlight-stream/moonlight-qt-deps/releases/tag/v15). SHA-256: `60003d5cf5147100352dede9836c1ba3c537dfff938fe0e3ef947bd4f51ca622`. Downloaded and verified locally. The build harness records every extracted file's hash and available DLL version metadata; missing embedded versions remain blank rather than inferred. The prebuilt dependency project's source/build recipes and Qt's corresponding sources/license obligations must accompany release preparation. No public release is qualified by this import.

Observed DLL product versions: FFmpeg revision `d32b387` (avcodec/avformat 63.1.100, avutil 61.1.100, swscale 10.1.100), dav1d 1.5.4, OpenSSL 3.6.4, libplacebo 7.371.0, SDL2 compatibility DLL 2.32.70, SDL3 3.4.16, and SDL2_ttf 2.25.0. Opus and discord-rpc DLLs expose no product version in this archive; their hashes identify the inputs.

## Evidence and remaining gates

| Check | Result |
| --- | --- |
| Local planning files compared to GitHub before import | Pass; existing files match |
| Upstream source and recursive submodules retrieved | Pass |
| Dependency archive downloaded and checksum verified | Pass |
| New PowerShell scripts parse | Pass |
| Workflow syntax and expressions | Pass; actionlint 1.7.12 on both new workflows |
| Application, qmake, native and upstream packaging source unchanged | Pass; empty diff against upstream |
| Deployed upstream CLI startup on the local Windows machine | Pass; portable `Moonlight.exe --help` exited 0, using packaged Qt/runtime DLLs |
| Unmodified upstream Windows x64 build | Pass; [run 34736992552](https://github.com/Unitron07/Asteria-Windows/actions/runs/34736992552), portable ZIP and symbols uploaded |
| Candidate Windows x64 build and artifacts | Pass; same run, portable ZIP and symbols uploaded; PR head `eef602e793ae72122d21305d1128d5e7daafa25f` |
| Owner's manual baseline test | Owner reported success before merging PR #1; exact client, host versions, and individual cases were not supplied |
| Native ARM64 upstream and candidate builds | Pass; all four x64/ARM64 jobs passed in [run 34790903403](https://github.com/Unitron07/Asteria-Windows/actions/runs/34790903403), PR #6 head `be43f5d6fe692b0884ec8cdb2486f8457f4fdd7d`; merged as `86c2ce98129ba27b975540624c9f262ed86279b9` |
| Final portable ZIP architecture gate | Implemented for both targets; local synthetic package tests pass, including deliberately injected foreign-architecture DLLs and malformed PE headers. Hosted upstream/candidate checks for both targets now pass in [run 34797782854](https://github.com/Unitron07/Asteria-Windows/actions/runs/34797782854) |
| Native ARM64 hardware validation | No real-device qualification evidence recorded; remains the M0A priority |
| Local compile | Not run: Qt/MSVC absent |
| Clean-machine portable launch | No separate clean-machine evidence recorded |
| Sunshine pairing and 1080p60 H.264 SDR with audio/input/gamepad | Per-case results and host version not recorded |
| Apollo pairing and the same stream test | Per-case results and host version not recorded |
| GPU decoder, performance measurements, Windows 10 minimum build | No qualification evidence recorded |

Import review: [PR #1](https://github.com/Unitron07/Asteria-Windows/pull/1). Initial integration commit: `cf43c38fa443316d444c8a71a808acfb5aeac609`; its two parents are the planning and upstream revisions above.

The first upstream CI job successfully built and packaged Moonlight 6.1.0. Its portable ZIP was downloaded, verified against the artifact hash report (`52ba768f0ea6351a7282e332d49146d9f752f2392b66483bdf1e7f7f79b7b9d6`), and smoke-tested locally with `--help`. `portable.dat` and source notices are present. The source archive includes nested submodule files and excludes Git metadata, downloaded libraries, and generated build outputs. An evidence-only quoting bug found in that run was fixed in `eef602e793ae72122d21305d1128d5e7daafa25f`; the corrected upstream and candidate jobs then passed in run `34736992552`. CLI startup is not GUI or streaming qualification.

The project owner's statement, "i have confirmed it works", is recorded as a successful manual baseline test, not as evidence that every release-checklist case or both host products were exercised. The owner subsequently merged PR #1. The historical M0 qualification gate is therefore only partly evidenced; its remaining local-build, clean-machine, host-version, decoder, and performance records carry forward into M0A/M5 rather than holding the completed source import open.

The [feature audit](FEATURE_AUDIT.md) remains the source-based feature inventory. No performance numbers are claimed. Use [VALIDATION.md](VALIDATION.md) to record the actual client architecture, hardware, drivers, host versions, stream settings, and results for both x64 and ARM64. Broad support claims remain gated on those results.

## M0A package architecture evidence

`scripts/build-baseline.ps1` now invokes `scripts/test-package-architecture.ps1` after adding source notices to the final portable ZIP. Every EXE and DLL entry is checked, including nested plugins, against exact x64 (`0x8664`) or ARM64 (`0xAA64`) machine type. Missing client/runtime files and malformed PE headers fail validation. ARM64EC/ARM64X and x86 are not accepted as native ARM64. This checks binary architecture, not full loader compatibility or dependency completeness.

The report at `build/evidence/<architecture>/package-architecture.json` records the ZIP SHA-256, per-binary machine types, and errors. A failed check stops normal artifact uploads; CI still attempts the evidence upload. The local test suite uses synthetic PE headers, not runnable applications, and does not establish device or decoder support. Attach hosted reports and real-device results before closing issue #3.

### ARM64 CRT packaging correction

Post-merge [run 34793336338](https://github.com/Unitron07/Asteria-Windows/actions/runs/34793336338) passed the x64 job but rejected the upstream ARM64 ZIP: `vcruntime140_1.dll` had x64 machine type `0x8664`. Compilation succeeded. The log shows upstream's wildcard CRT copy included this file from Visual Studio's `14.51.36231/arm64/Microsoft.VC145.CRT` directory; candidate jobs were skipped.

The harness now runs `repair-arm64-package.ps1` before the unchanged strict architecture validator. It only removes the root `vcruntime140_1.dll` when it is x64 and MSVC `dumpbin /dependents` succeeds for every other packaged EXE/DLL with no normal or delay-load import of that name. It retains a native ARM64 version, rejects inspection failures, and leaves unrelated wrong-architecture files for the validator to reject. The correction applies equally to upstream and candidate portable ZIPs without changing upstream application sources or installer output.

`arm64-runtime-cleanup.json` records before/after ZIP hashes, the decision, and dependency output for each inspected binary. Local regression cases pass for unused, normal-imported, delay-imported, absent, native, inspection-failure, malformed-output, and unrelated-x64 cases. These use a dumpbin test double; the successful hosted run recorded below additionally validates the actual tool and binaries. Static import inspection does not establish dynamic loading behavior or replace Surface/device testing.

## Current preview baseline

[PR #9](https://github.com/Unitron07/Asteria-Windows/pull/9) merged the Asteria identity/rebrand. All four upstream/candidate x64/ARM64 jobs passed in [run 34797782854](https://github.com/Unitron07/Asteria-Windows/actions/runs/34797782854) at `ab69dc3f76ff6b163ab91c35c3795d4da478f022`, including the CRT correction and strict final-ZIP architecture checks described above. This supersedes earlier pending hosted-validation notes; it does not qualify native ARM64 execution, clean-machine launch, decoding, or streaming. Real Windows 11 ARM64 device evidence remains pending.
