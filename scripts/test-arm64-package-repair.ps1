$ErrorActionPreference = 'Stop'
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('asteria-repair-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
$repair = Join-Path $PSScriptRoot 'repair-arm64-package.ps1'
# Test doubles supply dumpbin output; hosted builds exercise the real MSVC tool.
$dumpbin = Join-Path $scratch 'dumpbin.ps1'
@'
param($Option1, $Option2, $File)
$global:LASTEXITCODE = 0
if ($env:ASTERIA_REPAIR_TEST_MODE -eq 'error') { $global:LASTEXITCODE = 1; return }
if ($env:ASTERIA_REPAIR_TEST_MODE -eq 'malformed') { 'unrecognized'; return }
'File Type: DLL'
'  Image has the following dependencies:'
'    KERNEL32.dll'
if ($env:ASTERIA_REPAIR_TEST_MODE -eq 'normal') { '    VCRUNTIME140_1.dll' }
if ($env:ASTERIA_REPAIR_TEST_MODE -eq 'delay') {
    '  Image has the following delay load dependencies:'
    '    vcruntime140_1.dll'
}
'  Summary'
'        1000 .text'
'@
| Set-Content -LiteralPath $dumpbin
function New-Header([uint16]$Machine) {
    $bytes = [byte[]]::new(256)
    $bytes[0] = 0x4D; $bytes[1] = 0x5A
    [BitConverter]::GetBytes([uint32]64).CopyTo($bytes, 60)
    [BitConverter]::GetBytes([uint32]0x4550).CopyTo($bytes, 64)
    [BitConverter]::GetBytes($Machine).CopyTo($bytes, 68)
    [BitConverter]::GetBytes([uint16]112).CopyTo($bytes, 84)
    [BitConverter]::GetBytes([uint16]0x20B).CopyTo($bytes, 88)
    return ,$bytes
}
$savedMode = $env:ASTERIA_REPAIR_TEST_MODE
try {
    foreach ($mode in @('unused', 'normal', 'delay', 'error', 'malformed', 'native', 'absent', 'other-x64')) {
        $env:ASTERIA_REPAIR_TEST_MODE = $mode
        $package = Join-Path $scratch "$mode.zip"
        $reportPath = Join-Path $scratch "$mode.json"
        $zip = [IO.Compression.ZipFile]::Open($package, [IO.Compression.ZipArchiveMode]::Create)
        try {
            $files = @{'Asteria.exe' = 0xAA64; 'plugins/nested/Qt.dll' = 0xAA64}
            if ($mode -ne 'absent') { $files['vcruntime140_1.dll'] = if ($mode -eq 'native') { 0xAA64 } else { 0x8664 } }
            if ($mode -eq 'other-x64') { $files['plugins/other.dll'] = 0x8664 }
            foreach ($name in $files.Keys) {
                $stream = $zip.CreateEntry($name).Open()
                try { $bytes = New-Header $files[$name]; $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
            }
        } finally { $zip.Dispose() }
        $before = (Get-FileHash $package).Hash
        $failure = $null
        try { & $repair -PackagePath $package -DumpbinPath $dumpbin -ReportPath $reportPath -ClientExecutable 'Asteria.exe' } catch { $failure = $_.Exception.Message }
        $expectedFailure = $mode -in @('normal', 'delay', 'error', 'malformed')
        if ([bool]$failure -ne $expectedFailure) { throw "Unexpected result for ${mode}: $failure" }
        $report = Get-Content $reportPath -Raw | ConvertFrom-Json
        $removed = $mode -in @('unused', 'other-x64')
        if ($report.removed -ne $removed) { throw "Wrong removal state: $mode" }
        if (!$removed -and (Get-FileHash $package).Hash -ne $before) { throw "Package changed unexpectedly: $mode" }
        if ($report.beforeSha256 -ne $before -or $report.afterSha256 -ne (Get-FileHash $package).Hash) { throw 'Incorrect evidence hashes' }
        if ($removed -and !($report.imports.path -contains 'plugins/nested/Qt.dll')) { throw 'Nested plugin was not scanned' }
        if (!$expectedFailure) {
            $validationFailed = $false
            try { & (Join-Path $PSScriptRoot 'test-package-architecture.ps1') -PackagePath $package -Architecture arm64 -ReportPath (Join-Path $scratch "$mode-architecture.json") -ClientExecutable 'Asteria.exe' }
            catch { if ($mode -ne 'other-x64' -or $_.Exception.Message -notlike '*plugins/other.dll: Machine*') { throw }; $validationFailed = $true }
            if (($mode -eq 'other-x64') -ne $validationFailed) { throw 'Architecture gate did not reject unrelated x64 contamination' }
        }
        Write-Host "PASS: $mode"
    }
} finally {
    $env:ASTERIA_REPAIR_TEST_MODE = $savedMode
    $resolvedScratch = [IO.Path]::GetFullPath($scratch)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolvedScratch.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe scratch cleanup path' }
    Remove-Item -LiteralPath $resolvedScratch -Recurse -Force
}
