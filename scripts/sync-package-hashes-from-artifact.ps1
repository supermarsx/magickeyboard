param(
  [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string] $ArtifactPath
)

$ErrorActionPreference = 'Stop'

function Get-Sha256Hex {
  param([string] $Path)
  $stream = [System.IO.File]::OpenRead($Path)
  try {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
      $hashBytes = $sha.ComputeHash($stream)
    }
    finally {
      $sha.Dispose()
    }
  }
  finally {
    $stream.Dispose()
  }
  return (-join ($hashBytes | ForEach-Object { $_.ToString('x2') })).ToUpperInvariant()
}

$bucketPath = Join-Path $RepoRoot 'bucket/magickeyboard.json'
$wingetPath = Join-Path $RepoRoot 'winget/magickeyboard.yaml'

if (-not (Test-Path -LiteralPath $bucketPath)) { throw "Missing file: $bucketPath" }
if (-not (Test-Path -LiteralPath $wingetPath)) { throw "Missing file: $wingetPath" }

$bucket = Get-Content -LiteralPath $bucketPath -Raw | ConvertFrom-Json
$version = "$($bucket.version)".Trim()
if ([string]::IsNullOrWhiteSpace($version)) { throw 'bucket version is empty' }

if ([string]::IsNullOrWhiteSpace($ArtifactPath)) {
  $ArtifactPath = Join-Path $RepoRoot ("dist/All.Keyboard.Layouts.{0}.zip" -f $version)
}

if (-not (Test-Path -LiteralPath $ArtifactPath)) {
  throw "Artifact file not found: $ArtifactPath"
}

$hash = Get-Sha256Hex -Path $ArtifactPath
Write-Host "[sync-local] Artifact: $ArtifactPath"
Write-Host "[sync-local] Computed SHA256: $hash"

$bucket.hash = $hash
$bucket | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $bucketPath -NoNewline

$winget = Get-Content -LiteralPath $wingetPath -Raw
$winget = [regex]::Replace($winget, '(?m)^(\s*InstallerSha256\s*:\s*)[A-Fa-f0-9]{64}\s*$', "`${1}$hash")
Set-Content -LiteralPath $wingetPath -Value $winget -NoNewline

Write-Host '[sync-local] Updated bucket and winget hashes from local artifact.'
