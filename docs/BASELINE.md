# M0 baseline report and provenance

Prepared September 12, 2026. M0 is **in progress**. This report distinguishes source checks from build and hardware results.

## Imported history

- Planning parent: `Unitron07/Artemis-Windows` at `062306920ffb8b7bec9d07b6eb119401e035a1ea`.
- Upstream: `https://github.com/moonlight-stream/moonlight-qt.git` at `e3fd29e4d7dc5723d8d0da7d19e2698daec74456`.
- Integration branch: `codex/m0-moonlight-baseline`. The merge retains both ancestries. Merge this PR with a **merge commit**, not squash/rebase, to retain upstream history in main.
- The audit snapshot is the initial build candidate, not yet a qualified support baseline. No Android or Apollo implementation is imported.
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
| Unmodified upstream Windows build | Pending CI |
| Candidate Windows build and artifacts | Pending CI |
| Local compile | Not run: Qt/MSVC absent |
| Clean-machine portable launch | Not tested |
| Sunshine pairing and 1080p60 H.264 SDR with audio/input/gamepad | Not tested; host version not selected |
| Apollo pairing and the same stream test | Not tested; host version not selected |
| GPU decoder, performance measurements, Windows 10 minimum build | Not tested |

Import review: [PR #1](https://github.com/Unitron07/Artemis-Windows/pull/1). Initial integration commit: `cf43c38fa443316d444c8a71a808acfb5aeac609`; its two parents are the planning and upstream revisions above.

The existing [feature audit](FEATURE_AUDIT.md) is the source-based feature inventory. No performance numbers are claimed. Record hardware, drivers, host versions, stream settings, warm-up, three measured runs, logs, and pass/fail results using [VALIDATION.md](VALIDATION.md). M0 remains open until local and CI builds, clean-machine launch, and independent Sunshine/Apollo streaming checks pass.
