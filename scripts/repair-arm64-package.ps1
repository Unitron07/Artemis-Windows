[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PackagePath,
    [Parameter(Mandatory)][string]$DumpbinPath,
    [Parameter(Mandatory)][string]$ReportPath
)
$ErrorActionPreference = 'Stop'
$PackagePath = (Resolve-Path -LiteralPath $PackagePath).Path
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('artemis-imports-' + [guid]::NewGuid().ToString('N'))
$report = [ordered]@{
    package = [IO.Path]::GetFileName($PackagePath)
    beforeSha256 = (Get-FileHash -LiteralPath $PackagePath).Hash
    removed = $false
    reason = $null
    imports = @()
    afterSha256 = $null
}
$zip = $null
try {
    $zip = [IO.Compression.ZipFile]::OpenRead($PackagePath)
    $targets = @($zip.Entries | Where-Object { $_.FullName -ieq 'vcruntime140_1.dll' })
    if ($targets.Count -eq 0) { $report.reason = 'Known surplus runtime absent'; return }
    if ($targets.Count -ne 1) { throw 'Duplicate vcruntime140_1.dll entries' }
    $reader = [IO.BinaryReader]::new($targets[0].Open())
    try {
        $bytes = $reader.ReadBytes([int]$targets[0].Length)
        if ($bytes.Length -lt 64 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { throw 'Invalid runtime DOS header' }
        $offset = [BitConverter]::ToUInt32($bytes, 60)
        if ($offset -lt 64 -or [long]$offset + 6 -gt $bytes.Length -or [BitConverter]::ToUInt32($bytes, $offset) -ne 0x4550) {
            throw 'Invalid runtime PE header'
        }
        $machine = [BitConverter]::ToUInt16($bytes, $offset + 4)
    } finally { $reader.Dispose() }
    if ($machine -eq 0xAA64) { $report.reason = 'Runtime is native ARM64; retained'; return }
    if ($machine -ne 0x8664) { throw ('Unexpected runtime machine 0x{0:X4}' -f $machine) }
    New-Item -ItemType Directory -Path $scratch | Out-Null
    $binaries = @($zip.Entries | Where-Object { $_.FullName -match '(?i)\.(exe|dll)$' -and $_.FullName -ine 'vcruntime140_1.dll' })
    if (!($binaries | Where-Object { $_.Name -ieq 'Moonlight.exe' })) { throw 'Missing client for dependency inspection' }
    $index = 0
    foreach ($entry in $binaries) {
        # Use generated filenames, never archive paths, when extracting for inspection.
        $file = Join-Path $scratch ("binary-$index" + [IO.Path]::GetExtension($entry.Name))
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $file)
        $index++
        $output = @(& $DumpbinPath /nologo /dependents $file 2>&1)
        if ($LASTEXITCODE -ne 0 -or !$output.Count) { throw "Dependency inspection failed: $($entry.FullName)" }
        $dump = $output -join "`n"
        # /DEPENDENTS includes both normal and delay-load dependency lists.
        if ($dump -notmatch '(?im)^\s*File Type: DLL\s*$|^\s*File Type: EXECUTABLE IMAGE\s*$') {
            throw "Unrecognized dependency inspection output: $($entry.FullName)"
        }
        $report.imports += [pscustomobject]@{ path = $entry.FullName; dumpbin = $dump }
        if ($dump -match '(?im)^\s*vcruntime140_1\.dll\s*$') {
            throw "Cannot remove vcruntime140_1.dll: imported by $($entry.FullName)"
        }
    }
    $zip.Dispose(); $zip = $null
    # The only permitted removal is the verified x64 root CRT DLL, after every scan passed.
    $zip = [IO.Compression.ZipFile]::Open($PackagePath, [IO.Compression.ZipArchiveMode]::Update)
    @($zip.Entries | Where-Object { $_.FullName -ieq 'vcruntime140_1.dll' })[0].Delete()
    $zip.Dispose(); $zip = $null
    $report.removed = $true
    $report.reason = 'Removed x64 CRT DLL with no normal or delay-load imports in remaining packaged binaries'
    Write-Host 'Removed unused x64 vcruntime140_1.dll from ARM64 portable ZIP'
} catch {
    $report.reason = $_.Exception.Message
    throw
} finally {
    if ($zip) { $zip.Dispose() }
    $report.afterSha256 = (Get-FileHash -LiteralPath $PackagePath).Hash
    New-Item -ItemType Directory -Force -Path (Split-Path ([IO.Path]::GetFullPath($ReportPath)) -Parent) | Out-Null
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ReportPath -Encoding utf8
    $resolvedScratch = [IO.Path]::GetFullPath($scratch)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolvedScratch.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe scratch cleanup path' }
    if (Test-Path -LiteralPath $resolvedScratch) { Remove-Item -LiteralPath $resolvedScratch -Recurse -Force }
}
