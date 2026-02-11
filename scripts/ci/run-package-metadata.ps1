param(
  [string] $EventName,
  [string] $Ref,
  [string] $Actor,
  [string] $GithubOutputPath = $env:GITHUB_OUTPUT,
  [string] $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($GithubOutputPath)) {
  throw 'GITHUB_OUTPUT path is required.'
}

Push-Location $RepoRoot
try {
  # Hashes are synced from the freshly packaged artifact in the package job.
  "updated=false" | Out-File -FilePath $GithubOutputPath -Encoding utf8 -Append

  # Skip remote verification on main pushes because release artifact is produced later in this workflow.
  if (-not ($EventName -eq 'push' -and $Ref -eq 'refs/heads/main')) {
    & "$RepoRoot\scripts\verify-package-metadata.ps1"
  }
}
finally {
  Pop-Location
}
