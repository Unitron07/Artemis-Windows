# Shared preflight functions; this file does not change the caller's environment.
function Assert-BaselineDependencies {
    param([string]$SourceRoot, [string]$Architecture)
    $target = Join-Path $SourceRoot 'libs/windows'
    $marker = Join-Path $target 'baseline-dependencies.json'
    if (!(Test-Path -LiteralPath $marker)) { throw 'Run setup-baseline-deps.ps1 in a fresh checkout first.' }
    $installed = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
    $pin = (Get-Content (Join-Path $PSScriptRoot 'baseline-deps.json') -Raw | ConvertFrom-Json).$Architecture
    if ($installed.architecture -ne $Architecture -or $installed.sha256 -ne $pin.sha256 -or $installed.url -ne $pin.url) {
        throw "Dependencies do not match $Architecture. Use separate fresh checkouts for x64 and ARM64."
    }
    $inventory = @(Get-Content (Join-Path $SourceRoot "build/evidence/$Architecture/dependency-files.json") -Raw | ConvertFrom-Json)
    $files = @(Get-ChildItem -LiteralPath $target -Recurse -File | Where-Object { $_.FullName -ne $marker })
    if (!$inventory.Count -or $files.Count -ne $inventory.Count) { throw 'Dependency files changed; use a fresh checkout.' }
    foreach ($file in $inventory) {
        $path = Join-Path $target $file.path
        if (!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.sha256) {
            throw "Dependency file changed: $($file.path). Use a fresh checkout."
        }
    }
}

function Resolve-BaselineQt {
    param([string]$Architecture, [string]$QtBin)
    if (!$QtBin) {
        $candidates = @(Get-Command qmake.exe, qmake.bat, host-qmake.bat -All -ErrorAction SilentlyContinue |
            ForEach-Object { Split-Path $_.Source -Parent } | Sort-Object -Unique)
        if ($candidates.Count -ne 1) { throw 'Specify -QtBin explicitly when PATH has zero or multiple Qt kits.' }
        $QtBin = $candidates[0]
    }
    $QtBin = (Resolve-Path -LiteralPath $QtBin).Path.TrimEnd('\', '/')
    if ($QtBin -match '[\s!&()%\^]') { throw 'Use a Qt path without spaces or shell metacharacters.' }
    $kit = if ($Architecture -eq 'arm64') { 'msvc2022_arm64' } else { 'msvc2022_64' }
    if ((Split-Path $QtBin -Leaf) -ne 'bin' -or (Split-Path (Split-Path $QtBin -Parent) -Leaf) -ne $kit) {
        throw "The $Architecture target requires the $kit/bin Qt kit."
    }
    Resolve-BaselineQmake -QtBin $QtBin | Out-Null
    if ($Architecture -eq 'arm64') {
        $hostBin = Join-Path (Split-Path (Split-Path $QtBin -Parent) -Parent) 'msvc2022_64/bin'
        foreach ($tool in @('qmake.exe', 'windeployqt.exe')) {
            if (!(Test-Path (Join-Path $hostBin $tool))) { throw "ARM64 cross kit requires matching x64 host tool: $tool" }
        }
    }
    return $QtBin
}

# Match upstream build-arch.bat: the ARM64 kit may contain an ARM64
# qmake.exe alongside a host-qmake.bat cross-compilation forwarder.
function Resolve-BaselineQmake {
    param([string]$QtBin)
    foreach ($name in @('qmake.bat', 'host-qmake.bat', 'qmake.exe')) {
        $candidate = Join-Path $QtBin $name
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    throw 'Selected target kit has no qmake executable or forwarder.'
}
