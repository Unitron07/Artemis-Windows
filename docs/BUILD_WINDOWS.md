# Windows baseline builds

Moonlight PC at `e3fd29e4d7dc5723d8d0da7d19e2698daec74456` was imported through PR #1 and merged into `main`. The executable still identifies itself as Moonlight. The commands below describe the existing, CI-validated **x64** harness. Native ARM64 is the next priority; its implementation checklist follows below.

## Prerequisites

- A complete Git for Windows installation, PowerShell, and a checkout path without spaces or shell metacharacters, such as `C:\src\Artemis`. Upstream batch scripts do not consistently quote paths.
- Qt **6.11.2**, Windows **MSVC 2022 x64** kit (`msvc2022_64`); put its `bin` directory on PATH. MinGW is unsupported. CI uses the upstream-pinned aqtinstall revision recorded in the workflow.
- Visual Studio with the Desktop development with C++ workload, x64 MSVC compiler, and Windows SDK. Upstream names Visual Studio 2026; its CI uses `windows-2025`. The kit name is not proof of the selected compiler: the build evidence records `vswhere`, `cl /Bv`, `VCToolsVersion`, and Windows SDK values.
- 7-Zip on PATH. Upstream uses WiX/MSBuild with NuGet restore even when producing a portable package, so network access is needed.

## Candidate

Run in PowerShell, substituting the reviewed branch or commit when appropriate:

```powershell
git clone --recursive --branch main https://github.com/Unitron07/Artemis-Windows.git C:\src\Artemis
Set-Location C:\src\Artemis
git remote add upstream https://github.com/moonlight-stream/moonlight-qt.git
$env:PATH = 'C:\Qt\6.11.2\msvc2022_64\bin;C:\Program Files\7-Zip;' + $env:PATH
./scripts/setup-baseline-deps.ps1
./scripts/build-baseline.ps1
```

The dependency setup downloads only the upstream v15 x64 archive, verifies the checked-in SHA-256 before extraction, and records per-file hashes and available version metadata. It refuses an existing `libs/windows` directory; use a fresh checkout to repeat dependency setup. Subsequent builds can reuse verified dependencies. The upstream build script replaces its own `build/*-x64-release` output directories.

The wrapper calls unchanged `scripts/build-arch.bat Release`, which configures qmake, compiles using jom or nmake, deploys runtime DLLs, builds the MSI internally, and produces the portable ZIP and symbol ZIP. No signing or release credentials are required. Outputs:

- `build/installer-x64-release/MoonlightPortable-x64-*.zip`
- `build/symbols-x64-release/MoonlightDebuggingSymbols-x64-*.zip`
- `build/evidence/`: build transcript, source/submodule revisions, compiler/SDK information, dependency versions/hashes, artifact hashes, runner image metadata when available, and a source archive including recursive submodule contents. Source notices are included in the portable ZIP.

The wrapper unsets `CI_VERSION` while building so upstream includes **portable.dat**. Extract into a separate writable folder and keep that marker. The application is still Moonlight; using non-portable mode may share an installed Moonlight profile. M1 will introduce Artemis identity isolation.

## Unmodified upstream comparison

Use a second checkout; do not switch the candidate's working tree:

```powershell
git clone https://github.com/moonlight-stream/moonlight-qt.git C:\src\MoonlightBaseline
git -C C:\src\MoonlightBaseline checkout --detach e3fd29e4d7dc5723d8d0da7d19e2698daec74456
git -C C:\src\MoonlightBaseline submodule update --init --recursive
C:\src\Artemis\scripts\setup-baseline-deps.ps1 -SourceRoot C:\src\MoonlightBaseline
C:\src\Artemis\scripts\build-baseline.ps1 -SourceRoot C:\src\MoonlightBaseline
```

Both source trees use the same external dependency/build harness. No application, qmake, native-library, or upstream packaging changes are applied for this import.

## Native ARM64: next implementation target

The current Artemis wrappers hard-code x64: `baseline-deps.json` selects the x64 archive, `build-baseline.ps1` captures an AMD64 toolchain and x64 outputs, and the active workflow installs only the x64 Qt kit. Passing an ARM64 argument to these wrappers is not supported yet. The retained upstream `build-arch.bat` and `build-win-mac.yml` contain ARM64 integration to reuse in [M0A](NEXT_STEP.md).

M0A will use the pinned upstream Qt `win64_msvc2022_arm64_cross_compiled` kit (target directory `msvc2022_arm64`) with its x64 host tools, the corresponding MSVC cross compiler, and the Windows ARM64 dependency archive. Native refers to the resulting ARM64 application and runtime; the compiler can run on x64. Verify the selected toolchain and each deployed binary's architecture, not only the kit or filename.

Keep separate target dependency roots, build outputs, ZIP names, symbols, and evidence. Architecture-specific results must include source/submodule revisions, Qt/SDK/compiler versions, verified archive hashes, and a PE architecture inventory of the deployed runtime. Publish working ARM64 commands here only after the new harness is tested; until then, use the [next-step specification](NEXT_STEP.md) for implementation.

## CI and qualification

`Windows baseline` runs on main and `codex/**` pushes, PRs targeting main, and manual dispatch. The upstream job must pass before the candidate starts. Both use recursive checkout and the same pinned Qt/dependency/action inputs. Existing non-Windows reusable workflows remain in the tree for upstream maintenance but are not invoked by this Windows workflow. Tokens are read-only and checkout credentials are not persisted. Logs upload even when the build fails.

The x64 upstream and candidate builds passed in [run 34736992552](https://github.com/Unitron07/Artemis-Windows/actions/runs/34736992552). The owner reported a successful manual test before merging PR #1; detailed client/host records remain in the qualification backlog.

Hosted builds do not validate GPU decoding, pairing, performance, or OS compatibility. Complete the [baseline report](BASELINE.md) and [validation checklist](VALIDATION.md) on real x64 and ARM64 Windows machines against separately recorded Sunshine and Apollo versions. These CI packages are development evidence, not a qualified Artemis release. ARM64 qualification is part of M0A and the first-preview scope; Windows 10 x64 compatibility remains separate.
