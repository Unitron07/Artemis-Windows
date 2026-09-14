# Run with PowerShell 7; no Qt/MSVC installation or network is needed.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'baseline-preflight.ps1')
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('artemis-preflight-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
function Assert-Rejected {
    param([scriptblock]$Action, [string]$Message)
    try { & $Action } catch {
        if ($_.Exception.Message -notlike "*$Message*") { throw }
        return
    }
    throw "Expected rejection: $Message"
}
foreach ($architecture in @('x64', 'arm64')) {
    $root = Join-Path $scratch $architecture
    $target = Join-Path $root 'libs/windows'
    $evidence = Join-Path $root "build/evidence/$architecture"
    New-Item -ItemType Directory -Force $target, $evidence | Out-Null
    $pin = (Get-Content (Join-Path $PSScriptRoot 'baseline-deps.json') -Raw | ConvertFrom-Json).$architecture
    $pin | ConvertTo-Json | Set-Content (Join-Path $target 'baseline-dependencies.json')
    $library = Join-Path $target 'fixture.lib'
    Set-Content $library 'original'
    @(@{path = 'fixture.lib'; sha256 = (Get-FileHash $library).Hash}) |
        ConvertTo-Json -AsArray | Set-Content (Join-Path $evidence 'dependency-files.json')
    Assert-BaselineDependencies $root $architecture
    $other = if ($architecture -eq 'x64') { 'arm64' } else { 'x64' }
    Assert-Rejected { Assert-BaselineDependencies $root $other } 'Dependencies do not match'
    Set-Content $library 'modified'
    Assert-Rejected { Assert-BaselineDependencies $root $architecture } 'Dependency file changed'
    Set-Content $library 'original'
    Set-Content (Join-Path $target 'unexpected.lib') 'extra'
    Assert-Rejected { Assert-BaselineDependencies $root $architecture } 'Dependency files changed'
}
$hostBin = Join-Path $scratch 'Qt/6.11.2/msvc2022_64/bin'
$targetBin = Join-Path $scratch 'Qt/6.11.2/msvc2022_arm64/bin'
New-Item -ItemType Directory -Force $hostBin, $targetBin | Out-Null
New-Item -ItemType File (Join-Path $hostBin 'qmake.exe'), (Join-Path $targetBin 'qmake.bat') | Out-Null
Resolve-BaselineQt x64 $hostBin | Out-Null
Assert-Rejected { Resolve-BaselineQt arm64 $hostBin } 'requires the msvc2022_arm64'
Assert-Rejected { Resolve-BaselineQt x64 $targetBin } 'requires the msvc2022_64'
Assert-Rejected { Resolve-BaselineQt arm64 $targetBin } 'requires matching x64 host tool'
New-Item -ItemType File (Join-Path $hostBin 'windeployqt.exe') | Out-Null
Resolve-BaselineQt arm64 $targetBin | Out-Null
$originalPath = $env:PATH
try {
    $env:PATH = "$hostBin;$targetBin;$originalPath"
    Assert-Rejected { Resolve-BaselineQt x64 } 'Specify -QtBin explicitly'
} finally { $env:PATH = $originalPath }
# Real Qt 6.11 ARM64 kits contain both a native qmake.exe and host-qmake.bat.
$forwarderBin = Join-Path $scratch 'forwarder/Qt/6.11.2/msvc2022_arm64/bin'
New-Item -ItemType Directory -Force $forwarderBin | Out-Null
New-Item -ItemType File (Join-Path $forwarderBin 'qmake.exe'), (Join-Path $forwarderBin 'host-qmake.bat') | Out-Null
if ((Split-Path (Resolve-BaselineQmake $forwarderBin) -Leaf) -ne 'host-qmake.bat') {
    throw 'ARM64 qmake.exe was selected instead of the host forwarder'
}
New-Item -ItemType File (Join-Path $forwarderBin 'qmake.bat') | Out-Null
if ((Split-Path (Resolve-BaselineQmake $forwarderBin) -Leaf) -ne 'qmake.bat') {
    throw 'qmake.bat must take precedence to match upstream'
}
if ((Split-Path (Resolve-BaselineQmake $hostBin) -Leaf) -ne 'qmake.exe') {
    throw 'x64 executable fallback is broken'
}
# Corrupt downloads must fail before any dependency directory is extracted.
function Invoke-WebRequest { param($Uri, $OutFile) Set-Content -LiteralPath $OutFile 'corrupt archive' }
$badRoot = Join-Path $scratch 'bad-download'
New-Item -ItemType Directory $badRoot | Out-Null
Assert-Rejected { & (Join-Path $PSScriptRoot 'setup-baseline-deps.ps1') -SourceRoot $badRoot -Architecture arm64 } 'Dependency checksum mismatch'
if (Test-Path (Join-Path $badRoot 'libs/windows')) { throw 'A corrupt download was extracted' }
Write-Output "PASS: dependency integrity, architecture mismatch, Qt target and host-tool checks. Fixtures: $scratch"
