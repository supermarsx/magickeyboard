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
  $updated = $false

  if ($EventName -eq 'push' -and $Ref -eq 'refs/heads/main' -and $Actor -ne 'github-actions[bot]') {
    & "$RepoRoot\scripts\sync-package-hashes.ps1"
    $changed = (git status --porcelain -- bucket/magickeyboard.json winget/magickeyboard.yaml)
    if (-not [string]::IsNullOrWhiteSpace($changed)) {
      git config user.name "github-actions[bot]"
      git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
      git add bucket/magickeyboard.json winget/magickeyboard.yaml
      git commit -m "ci: sync package hashes"
      git push
      $updated = $true
    }
  }

  "updated=$($updated.ToString().ToLowerInvariant())" | Out-File -FilePath $GithubOutputPath -Encoding utf8 -Append
  & "$RepoRoot\scripts\verify-package-metadata.ps1"
}
finally {
  Pop-Location
}
