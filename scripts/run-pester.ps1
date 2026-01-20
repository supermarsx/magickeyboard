param(
  [string] $PesterPath = "../../tests/powershell/pester"
)

Remove-Module Pester -ErrorAction SilentlyContinue

# Prefer any installed Pester 5+ module (user or system scope). If none available, install into CurrentUser.
$pester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [Version]'5.0' } | Sort-Object Version -Descending | Select-Object -First 1
if (-not $pester) {
  Write-Host 'Pester 5 not found; installing to CurrentUser'
  Install-Module -Name Pester -Force -Scope CurrentUser -Confirm:$false -ErrorAction Stop
  $pester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [Version]'5.0' } | Sort-Object Version -Descending | Select-Object -First 1
}

if (-not $pester) {
  Write-Error 'Failed to locate or install Pester 5. Aborting tests.'
  exit 2
}

try {
  Import-Module -Name Pester -MinimumVersion 5.0 -Force -ErrorAction Stop
} catch {
  # If we located a module directory, try to import its module manifest (*.psd1). This is more reliable
  if ($pester -and $pester.ModuleBase) {
    $manifest = Get-ChildItem -Path $pester.ModuleBase -Filter *.psd1 -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($manifest) {
      try {
        Import-Module -Name $manifest.FullName -Force -ErrorAction Stop
      } catch {
        Write-Error "Failed to import Pester manifest from path $($manifest.FullName): $($_.Exception.Message)"
        exit 3
      }
    } else {
      try {
        Import-Module ($pester.ModuleBase) -Force -ErrorAction Stop
      } catch {
        Write-Error "Failed to import Pester module from known locations: $($_.Exception.Message)"
        exit 3
      }
    }
  } else {
    Write-Error 'Pester module information missing; cannot import.'
    exit 3
  }
}

# Invoke Pester using Pester 5 configuration (avoids deprecated legacy parameter sets)
$config = New-PesterConfiguration
$config.Run.Path = @($PesterPath)
$config.Run.Exit = $true
Invoke-Pester -Configuration $config
