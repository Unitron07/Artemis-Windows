[CmdletBinding()]
param([string]$SourceRoot = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$pin = Get-Content (Join-Path $PSScriptRoot 'baseline-deps.json') -Raw | ConvertFrom-Json
$target = Join-Path $SourceRoot 'libs/windows'
$evidence = Join-Path $SourceRoot 'build/evidence'
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
# Refuse to mix stale dependencies with the baseline. No recursive deletion here.
if (Test-Path -LiteralPath $target) {
    throw "Dependency directory already exists: $target. Use a fresh checkout."
}
$archive = Join-Path $evidence 'Windows-x64.zip'
Invoke-WebRequest -Uri $pin.url -OutFile $archive
$actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $pin.sha256) { throw "Dependency checksum mismatch: $actual" }
$pin | ConvertTo-Json | Set-Content (Join-Path $evidence 'dependencies.json') -Encoding utf8
Expand-Archive -LiteralPath $archive -DestinationPath $target
Remove-Item -LiteralPath $archive
Get-ChildItem -LiteralPath $target -Recurse -File | ForEach-Object {
    [pscustomobject]@{
        path = $_.FullName.Substring($target.Length + 1)
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        fileVersion = $_.VersionInfo.FileVersion
        productVersion = $_.VersionInfo.ProductVersion
    }
} | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $evidence 'dependency-files.json') -Encoding utf8
