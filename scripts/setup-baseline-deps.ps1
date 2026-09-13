[CmdletBinding()]
param(
    [string]$SourceRoot = (Split-Path $PSScriptRoot -Parent),
    [ValidateSet('x64', 'arm64')][string]$Architecture = 'x64'
)
$ErrorActionPreference = 'Stop'
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$Architecture = $Architecture.ToLowerInvariant()
$pin = (Get-Content (Join-Path $PSScriptRoot 'baseline-deps.json') -Raw | ConvertFrom-Json).$Architecture
$target = Join-Path $SourceRoot 'libs/windows'
$evidence = Join-Path $SourceRoot "build/evidence/$Architecture"
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
# Refuse to mix stale dependencies with the baseline. No recursive deletion here.
if (Test-Path -LiteralPath $target) {
    throw "Dependency directory already exists: $target. Use a fresh checkout."
}
$archive = Join-Path $evidence "Windows-$Architecture.zip"
Invoke-WebRequest -Uri $pin.url -OutFile $archive
$actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $pin.sha256) { throw "Dependency checksum mismatch: $actual" }
Expand-Archive -LiteralPath $archive -DestinationPath $target
if (!(Test-Path (Join-Path $target "lib/$Architecture")) -or
    !(Test-Path (Join-Path $target "include/$Architecture"))) {
    throw "Archive does not contain the expected $Architecture dependency layout. Use a fresh checkout."
}
Remove-Item -LiteralPath $archive
Get-ChildItem -LiteralPath $target -Recurse -File | ForEach-Object {
    [pscustomobject]@{
        path = $_.FullName.Substring($target.Length + 1)
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        fileVersion = $_.VersionInfo.FileVersion
        productVersion = $_.VersionInfo.ProductVersion
    }
} | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $evidence 'dependency-files.json') -Encoding utf8
# Write the completion marker last. One architecture per checkout preserves the
# unmodified upstream libs/windows layout without mixing its shared headers.
$pin | ConvertTo-Json | Set-Content (Join-Path $target 'baseline-dependencies.json') -Encoding utf8
$pin | ConvertTo-Json | Set-Content (Join-Path $evidence 'dependencies.json') -Encoding utf8
