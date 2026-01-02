param(
  [int] $ReleaseNumber = 2
)

Set-StrictMode -Version Latest

$root = Split-Path -Path $PSScriptRoot -Parent
$layoutDir = Join-Path $root 'All Keyboard Layouts (1.0.3.40)'
$outDir = Join-Path $root 'dist'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$releaseTag = "Release-$ReleaseNumber"
$version = $releaseTag

Write-Host "Creating release archive for $version"

# If a bash packager exists, prefer it for parity
if (Get-Command bash -ErrorAction SilentlyContinue) {
  Write-Host 'Bash detected — delegating to scripts/package_layouts.sh for packaging'
  & bash -lc "cd \"$root\" && ./scripts/package_layouts.sh $version"
} else {
  Write-Host 'No bash found — packaging with PowerShell Compress-Archive'
  $archiveName = "All.Keyboard.Layouts.$version.zip"
  $archivePath = Join-Path $outDir $archiveName
  if (Test-Path $archivePath) { Remove-Item -LiteralPath $archivePath -Force }
  Push-Location $layoutDir
  try {
    Compress-Archive -Path * -DestinationPath $archivePath -Force
    Write-Host "Created archive: $archivePath"
  } finally { Pop-Location }
}

# Locate archive (either created by bash script or Compress-Archive)
$archive = Get-ChildItem -Path $outDir -Filter "All.Keyboard.Layouts.*$version*.zip" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $archive) {
  $archive = Get-ChildItem -Path $outDir -Filter "*.zip" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

if (-not $archive) {
  Write-Error "No archive found in $outDir — aborting"
  exit 1
}

Write-Host "Archive ready: $($archive.FullName)"

# Create git tag if in a git repo
if (Get-Command git -ErrorAction SilentlyContinue) {
  try {
    git rev-parse --git-dir > $null 2>&1
    git tag -f $releaseTag
    git push --tags --force 2>$null || Write-Warning 'Failed to push tags (no credentials or remote)'
  } catch {
    Write-Warning 'Git not available or not a repository — skipping tag creation'
  }
} else {
  Write-Warning 'git not found — skipping tag creation'
}

# Create GitHub release if gh CLI available
if (Get-Command gh -ErrorAction SilentlyContinue) {
  try {
    gh release create $releaseTag $archive.FullName --title $releaseTag --notes "Automated release $releaseTag"
  } catch {
    Write-Warning "gh release creation failed: $($_.Exception.Message)"
  }
} else {
  Write-Host 'gh CLI not found — skipping GitHub release creation. Upload archive manually if desired.'
}

Write-Host "Release $releaseTag ready. Archive: $($archive.FullName)"
