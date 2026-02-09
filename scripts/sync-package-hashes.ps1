param(
  [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
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
$url = "$($bucket.url)".Trim()
if ([string]::IsNullOrWhiteSpace($url)) { throw 'bucket url is empty' }

$tmpFile = Join-Path ([IO.Path]::GetTempPath()) ("magickeyboard_sync_{0}.zip" -f [guid]::NewGuid().ToString('N'))
try {
  Write-Host "[sync] Downloading package from: $url"
  Invoke-WebRequest -Uri $url -OutFile $tmpFile
  $hash = Get-Sha256Hex -Path $tmpFile
  Write-Host "[sync] Computed SHA256: $hash"
}
finally {
  if (Test-Path -LiteralPath $tmpFile) {
    Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
  }
}

$bucket.hash = $hash
$bucket | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $bucketPath -NoNewline

$winget = Get-Content -LiteralPath $wingetPath -Raw
$winget = [regex]::Replace($winget, '(?m)^(\s*InstallerSha256\s*:\s*)[A-Fa-f0-9]{64}\s*$', "`${1}$hash")
Set-Content -LiteralPath $wingetPath -Value $winget -NoNewline

Write-Host '[sync] Updated bucket and winget hashes.'
