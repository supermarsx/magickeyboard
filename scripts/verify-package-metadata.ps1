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

function Get-WingetFieldValues {
  param(
    [string] $Path,
    [string] $FieldName
  )

  $pattern = "^\s*{0}\s*:\s*(.+?)\s*$" -f [regex]::Escape($FieldName)
  $values = @()
  foreach ($line in Get-Content -LiteralPath $Path) {
    $m = [regex]::Match($line, $pattern)
    if ($m.Success) {
      $v = $m.Groups[1].Value.Trim()
      if (($v.StartsWith("'") -and $v.EndsWith("'")) -or ($v.StartsWith('"') -and $v.EndsWith('"'))) {
        $v = $v.Substring(1, $v.Length - 2)
      }
      $values += $v
    }
  }
  return $values
}

$bucketPath = Join-Path $RepoRoot 'bucket/magickeyboard.json'
$wingetPath = Join-Path $RepoRoot 'winget/magickeyboard.yaml'

if (-not (Test-Path -LiteralPath $bucketPath)) { throw "Missing file: $bucketPath" }
if (-not (Test-Path -LiteralPath $wingetPath)) { throw "Missing file: $wingetPath" }

$bucket = Get-Content -LiteralPath $bucketPath -Raw | ConvertFrom-Json
$bucketUrl = "$($bucket.url)".Trim()
$bucketHash = "$($bucket.hash)".Trim().ToUpperInvariant()
$version = "$($bucket.version)".Trim()

if ([string]::IsNullOrWhiteSpace($bucketUrl)) { throw 'bucket url is empty' }
if ([string]::IsNullOrWhiteSpace($bucketHash)) { throw 'bucket hash is empty' }
if ([string]::IsNullOrWhiteSpace($version)) { throw 'bucket version is empty' }

$expectedFileName = "All.Keyboard.Layouts.$version.zip"
if ($bucketUrl -notmatch [regex]::Escape($expectedFileName)) {
  throw "bucket url does not contain expected file name '$expectedFileName': $bucketUrl"
}

if ($bucketHash -notmatch '^[A-F0-9]{64}$') {
  throw "bucket hash is not a valid SHA256 hex string: $bucketHash"
}

$wingetUrls = Get-WingetFieldValues -Path $wingetPath -FieldName 'InstallerUrl'
$wingetHashes = Get-WingetFieldValues -Path $wingetPath -FieldName 'InstallerSha256' | ForEach-Object { $_.ToUpperInvariant() }
$wingetVersion = (Get-WingetFieldValues -Path $wingetPath -FieldName 'PackageVersion' | Select-Object -First 1)

if (-not $wingetUrls -or $wingetUrls.Count -lt 1) { throw 'No InstallerUrl entries found in winget manifest' }
if (-not $wingetHashes -or $wingetHashes.Count -lt 1) { throw 'No InstallerSha256 entries found in winget manifest' }
if ([string]::IsNullOrWhiteSpace($wingetVersion)) { throw 'No PackageVersion entry found in winget manifest' }

if ($wingetVersion.Trim() -ne $version) {
  throw "Version mismatch: bucket=$version winget=$wingetVersion"
}

foreach ($u in $wingetUrls) {
  if ($u.Trim() -ne $bucketUrl) {
    throw "URL mismatch between bucket and winget manifests.`nbucket: $bucketUrl`nwinget: $u"
  }
}

foreach ($h in $wingetHashes) {
  if ($h -ne $bucketHash) {
    throw "Hash mismatch between bucket and winget manifests.`nbucket: $bucketHash`nwinget: $h"
  }
}

$tmpFile = Join-Path ([IO.Path]::GetTempPath()) ("magickeyboard_metadata_{0}.zip" -f [guid]::NewGuid().ToString('N'))
try {
  Write-Host "[verify] Downloading package from: $bucketUrl"
  Invoke-WebRequest -Uri $bucketUrl -OutFile $tmpFile
  $actualHash = Get-Sha256Hex -Path $tmpFile
  Write-Host "[verify] Downloaded SHA256: $actualHash"

  if ($actualHash -ne $bucketHash) {
    throw "Remote artifact hash mismatch.`nexpected: $bucketHash`nactual:   $actualHash"
  }
}
finally {
  if (Test-Path -LiteralPath $tmpFile) {
    Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
  }
}

Write-Host "[verify] Package metadata is consistent across Scoop/Winget and matches the live artifact."
