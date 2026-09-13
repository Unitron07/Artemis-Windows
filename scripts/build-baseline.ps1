[CmdletBinding()]
param([string]$SourceRoot = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
# Upstream build-arch.bat uses unquoted source paths.
if ($SourceRoot -match '[\s!&()%\^]') { throw 'Use a checkout path without spaces or shell metacharacters, for example C:\src\Artemis.' }
$evidence = Join-Path $SourceRoot 'build/evidence'
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
Start-Transcript -Path (Join-Path $evidence 'build.log') -Force | Out-Null
Push-Location $SourceRoot
try {
    $sha = git rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Unable to resolve source revision' }
    $submodules = @(git submodule status --recursive)
    if ($LASTEXITCODE -ne 0 -or ($submodules | Where-Object { $_ -match '^[-+U]' })) {
        throw 'Initialize recursive submodules at their pinned revisions first.'
    }
    $submodules | Set-Content (Join-Path $evidence 'submodules.txt') -Encoding utf8
    [pscustomobject]@{
        source = $sha
        configuration = 'Release x64; unsigned'
        command = 'scripts\build-arch.bat Release'
        os = [System.Environment]::OSVersion.VersionString
        runnerImage = $env:ImageVersion
        runnerImageOS = $env:ImageOS
    } | ConvertTo-Json | Set-Content (Join-Path $evidence 'build.json') -Encoding utf8
    foreach ($tool in @('qmake', '7z')) { Get-Command $tool -ErrorAction Stop | Out-Host }
    qmake -query
    if ($LASTEXITCODE -ne 0) { throw 'qmake failed' }
    # Match upstream's vswhere selection and record the actual compiler and SDK.
    $vswhere = Get-Command vswhere.exe -ErrorAction SilentlyContinue
    $vswherePath = if ($vswhere) { $vswhere.Source } else { Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe' }
    if (!(Test-Path -LiteralPath $vswherePath)) { throw 'Visual Studio Installer/vswhere is required' }
    $vsPath = & $vswherePath -latest -property installationPath
    if (!$vsPath) { throw 'No Visual Studio installation found' }
    $vcvars = Join-Path $vsPath 'VC/Auxiliary/Build/vcvarsall.bat'
    & $vswherePath -latest -format json | Set-Content (Join-Path $evidence 'visual-studio.json') -Encoding utf8
    # A batch file avoids PowerShell/cmd double-quoting of Program Files paths.
    @"
@echo off
call "$vcvars" AMD64
if errorlevel 1 exit /b 1
where cl
if errorlevel 1 exit /b 1
cl /Bv > build\evidence\compiler.txt 2>&1
rem cl /Bv without a source file reports a usage error after its version banner.
if not defined WindowsSDKVersion exit /b 1
if not defined VCToolsVersion exit /b 1
set WindowsSDK > build\evidence\sdk.txt
set VCToolsVersion >> build\evidence\sdk.txt
exit /b 0
"@ | Set-Content (Join-Path $evidence 'capture-toolchain.cmd') -Encoding ascii
    cmd /d /c build\evidence\capture-toolchain.cmd
    if ($LASTEXITCODE -ne 0) { throw 'Unable to capture compiler and SDK versions' }
    Get-Content (Join-Path $evidence 'compiler.txt'), (Join-Path $evidence 'sdk.txt') | Out-Host
    # With CI_VERSION unset upstream creates portable.dat, keeping this test
    # build's settings separate from an installed Moonlight user profile.
    $savedVersion = $env:CI_VERSION
    $env:CI_VERSION = $null
    try {
        cmd /d /c scripts\build-arch.bat Release
        if ($LASTEXITCODE -ne 0) { throw "Upstream build failed ($LASTEXITCODE)" }
    } finally { $env:CI_VERSION = $savedVersion }
    $deploy = Join-Path $SourceRoot 'build/deploy-x64-release'
    $notices = Join-Path $deploy 'source-notices'
    foreach ($license in @('LICENSE', 'h264bitstream/LICENSE',
        'qmdnsengine/qmdnsengine/LICENSE.txt', 'app/SDL_GameControllerDB/LICENSE',
        'moonlight-common-c/moonlight-common-c/LICENSE.txt',
        'moonlight-common-c/moonlight-common-c/enet/LICENSE',
        'moonlight-common-c/moonlight-common-c/nanors/LICENSE')) {
        $destination = Join-Path $notices $license
        New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
        Copy-Item -LiteralPath (Join-Path $SourceRoot $license) -Destination $destination
    }
    @"
Development baseline from https://github.com/moonlight-stream/moonlight-qt at $sha.
Source snapshot including pinned submodules is in the accompanying evidence artifact.
Dependency source/build recipes: https://github.com/moonlight-stream/moonlight-qt-deps/tree/v15
Qt source archives: https://download.qt.io/archive/qt/6.11/6.11.2/submodules/
This unsigned Moonlight baseline is not a qualified Artemis release.
"@ | Set-Content (Join-Path $notices 'PROVENANCE.txt') -Encoding utf8
    $package = @(Get-ChildItem build/installer-x64-release/*.zip)
    if ($package.Count -ne 1) { throw 'Expected exactly one portable ZIP' }
    7z a $package[0].FullName "$deploy\source-notices"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to include source notices' }
    tar -czf (Join-Path $evidence 'source.tar.gz') --exclude=.git --exclude=./build --exclude=./libs -C $SourceRoot .
    if ($LASTEXITCODE -ne 0) { throw 'Unable to archive source and submodules' }
    Get-ChildItem build/installer-x64-release/*.zip, build/symbols-x64-release/*.zip |
        Get-FileHash -Algorithm SHA256 | Format-Table -AutoSize | Out-String -Width 300 |
        Set-Content (Join-Path $evidence 'artifact-sha256.txt') -Encoding utf8
} finally {
    Pop-Location
    Stop-Transcript | Out-Null
}
