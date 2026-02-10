param(
  [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'

Push-Location $RepoRoot
try {
  cmd /c scripts\run-tests.bat
  if ($LASTEXITCODE -ne 0) {
    throw "run-tests.bat failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
