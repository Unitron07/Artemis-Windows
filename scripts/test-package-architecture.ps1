[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PackagePath,
    [Parameter(Mandatory)][ValidateSet('x64', 'arm64')][string]$Architecture,
    [Parameter(Mandatory)][string]$ReportPath,
    [string]$ClientExecutable = 'Asteria.exe'
)
$ErrorActionPreference = 'Stop'
$expected = if ($Architecture -eq 'arm64') { 0xAA64 } else { 0x8664 }
$PackagePath = (Resolve-Path -LiteralPath $PackagePath).Path
$results = [Collections.Generic.List[object]]::new()
$errors = [Collections.Generic.List[string]]::new()
$archive = $null
try {
    $archive = [IO.Compression.ZipFile]::OpenRead($PackagePath)
    $entries = @($archive.Entries | Where-Object { $_.FullName -match '(?i)\.(exe|dll)$' })
    if (!($entries | Where-Object { $_.Name -ieq $ClientExecutable })) {
        $errors.Add("Package is missing $ClientExecutable")
    }
    if (!($entries | Where-Object { $_.Name -match '(?i)\.dll$' })) {
        $errors.Add('Package contains no runtime DLLs')
    }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $entries) {
        $machine = $null
        $failure = $null
        $reader = $null
        try {
            if (!$seen.Add($entry.FullName.Replace('\', '/'))) { throw 'Duplicate binary path' }
            $reader = [IO.BinaryReader]::new($entry.Open())
            $dos = $reader.ReadBytes(64)
            if ($dos.Length -ne 64 -or $dos[0] -ne 0x4D -or $dos[1] -ne 0x5A) {
                throw 'Invalid or truncated DOS header'
            }
            $offset = [BitConverter]::ToUInt32($dos, 60)
            if ($offset -lt 64 -or [long]$offset + 26 -gt $entry.Length) { throw 'Invalid PE header offset' }
            # ZIP entry streams are not seekable. Skip only to the bounded header offset.
            $remaining = [long]$offset - 64
            while ($remaining -gt 0) {
                $chunk = $reader.ReadBytes([int][Math]::Min(4096, $remaining))
                if (!$chunk.Length) { throw 'Truncated PE header' }
                $remaining -= $chunk.Length
            }
            if ($reader.ReadUInt32() -ne 0x00004550) { throw 'Invalid PE signature' }
            $machine = $reader.ReadUInt16()
            $coff = $reader.ReadBytes(18)
            if ($coff.Length -ne 18) { throw 'Truncated COFF header' }
            $optionalSize = [BitConverter]::ToUInt16($coff, 14)
            if ($optionalSize -lt 112 -or [long]$offset + 24 + $optionalSize -gt $entry.Length) {
                throw 'Invalid or truncated PE32+ optional header'
            }
            if ($reader.ReadUInt16() -ne 0x020B) { throw 'Expected PE32+ optional header' }
            if ($machine -ne $expected) {
                throw ('Machine 0x{0:X4} does not match {1} (0x{2:X4})' -f $machine, $Architecture, $expected)
            }
        } catch {
            $failure = $_.Exception.Message
            $errors.Add("$($entry.FullName): $failure")
        } finally {
            if ($reader) { $reader.Dispose() }
        }
        $results.Add([pscustomobject]@{
            path = $entry.FullName
            machine = if ($null -ne $machine) { '0x{0:X4}' -f $machine } else { $null }
            passed = ($null -eq $failure)
            error = $failure
        })
    }
} catch {
    $errors.Add($_.Exception.Message)
} finally {
    if ($archive) { $archive.Dispose() }
}
$report = [pscustomobject]@{
    schemaVersion = 1
    package = [IO.Path]::GetFileName($PackagePath)
    sha256 = (Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash
    architecture = $Architecture.ToLowerInvariant()
    expectedMachine = '0x{0:X4}' -f $expected
    passed = ($errors.Count -eq 0)
    binaries = @($results.ToArray())
    errors = @($errors.ToArray())
}
$reportDirectory = Split-Path ([IO.Path]::GetFullPath($ReportPath)) -Parent
New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ReportPath -Encoding utf8
if (!$report.passed) { throw "Package architecture validation failed: $($errors -join '; ')" }
Write-Host "Verified $($results.Count) $Architecture binaries in $($report.package)"
