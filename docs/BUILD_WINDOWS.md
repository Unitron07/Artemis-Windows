# Windows baseline builds

Moonlight PC at `e3fd29e4d7dc5723d8d0da7d19e2698daec74456` was imported through PR #1 and merged into `main`. The executable still identifies itself as Moonlight. The harness now accepts `-Architecture x64` (default) or `-Architecture arm64`. Dependency setup and preflight checks have been tested for both; full ARM64 compilation and device qualification remain pending.

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

Dependency setup downloads the selected upstream v15 archive, verifies its checked-in SHA-256 before extraction, and records per-file hashes and available version metadata. It refuses an existing `libs/windows` directory. Use a separate fresh checkout per architecture: this isolates upstream's shared headers without modifying its source layout. A completion marker binds each checkout to one target; builds reject the wrong target, changed files, and extra files. Subsequent builds reuse these verified dependencies. See [dependency provenance](DEPENDENCIES_WINDOWS.md).

The wrapper calls unchanged `scripts/build-arch.bat Release`, which configures qmake, compiles using jom or nmake, deploys runtime DLLs, builds the MSI internally, and produces the portable ZIP and symbol ZIP. No signing or release credentials are required. Outputs:

- `build/installer-x64-release/MoonlightPortable-x64-*.zip`
- `build/symbols-x64-release/MoonlightDebuggingSymbols-x64-*.zip`
- `build/evidence/x64/`: build transcript, source/submodule revisions, compiler/SDK information, dependency versions/hashes, artifact hashes, runner image metadata when available, and a source archive including recursive submodule contents. Source notices are included in the portable ZIP. ARM64 uses `build/evidence/arm64/` and corresponding `*-arm64-release` output folders.

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

## Native ARM64 build setup

On an x64 Windows build host, install Qt 6.11.2's `win64_msvc2022_arm64_cross_compiled` kit (`msvc2022_arm64`) alongside its matching `msvc2022_64` host kit. Install MSVC ARM64 build tools and the Windows SDK through Visual Studio Installer. Keep both kits in the same Qt version directory. The wrapper checks the selected kit, requires Qt 6.11.2, removes other Qt tool directories from its temporary PATH, and records the target compiler/SDK. Upstream invokes the x64 host tools to generate and deploy the ARM64 application.

```powershell
git clone --recursive https://github.com/Unitron07/Artemis-Windows.git C:\src\Artemis-arm64
Set-Location C:\src\Artemis-arm64
./scripts/setup-baseline-deps.ps1 -Architecture arm64
./scripts/build-baseline.ps1 -Architecture arm64 -QtBin C:\Qt\6.11.2\msvc2022_arm64\bin
```

These are the implemented commands, not a claim of a completed ARM64 build. Use the same arguments with `-SourceRoot` for a separate pinned upstream ARM64 checkout. `-QtBin` is optional when PATH contains exactly one supported kit. Keep 7-Zip on PATH as for x64. Full ARM64 CI, deployed-binary PE checks, and hardware tests are the remaining [M0A work](NEXT_STEP.md). Run `pwsh -File scripts/test-baseline-preflight.ps1` to test the dependency and kit guards without Qt/MSVC.

## CI and qualification

`Windows baseline` builds x64 and ARM64 in separate jobs and runs on main and `codex/**` pushes, PRs targeting main, and manual dispatch. Both upstream architecture jobs must pass before the candidate jobs start. Each job uses its own fresh source checkout and architecture-specific dependency archive. CI installs the pinned Qt 6.11.2 x64 host kit and, for ARM64, the matching cross kit; the wrapper receives an explicit target and Qt path. Both use recursive checkout and the same pinned Qt/dependency/action inputs. Existing non-Windows reusable workflows remain in the tree for upstream maintenance but are not invoked by this Windows workflow. Tokens are read-only and checkout credentials are not persisted. Logs upload even when the build fails.

The x64 upstream and candidate builds passed in [run 34736992552](https://github.com/Unitron07/Artemis-Windows/actions/runs/34736992552). The owner reported a successful manual test before merging PR #1; detailed client/host records remain in the qualification backlog.

Hosted builds do not validate GPU decoding, pairing, performance, or OS compatibility. Complete the [baseline report](BASELINE.md) and [validation checklist](VALIDATION.md) on real x64 and ARM64 Windows machines against separately recorded Sunshine and Apollo versions. These CI packages are development evidence, not a qualified Artemis release. ARM64 qualification is part of M0A and the first-preview scope; Windows 10 x64 compatibility remains separate.

### CI artifact names

Each successful upstream/candidate architecture job uploads `baseline-<label>-windows-<architecture>-<run>`, `symbols-<label>-windows-<architecture>-<run>`, `source-<label>-windows-<architecture>-<run>`, and `evidence-<label>-windows-<architecture>-<run>`. Source includes recursive submodule contents. Evidence includes source and harness revisions, Qt host/target paths and versions for ARM64, compiler/SDK details, dependency inventory, and SHA-256 hashes for the portable, symbols, and source archives. Evidence uploads are attempted on failure as well. Package PE validation and real-device qualification remain separate M0A gates.
