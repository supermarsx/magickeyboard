param(
  [Parameter(Mandatory=$true)][string]$Key,
  [Parameter(Mandatory=$true)][string]$File
)

try {
  $json = Get-Content -Raw -Path $File | ConvertFrom-Json -ErrorAction Stop
} catch {
  Write-Error "Could not load translations file: $File"
  exit 2
}

$locale = (Get-UICulture).Name
if (-not $json.PSObject.Properties.Name -contains $Key) {
  Write-Error "Translations do not contain key: $Key"
  exit 3
}

$entry = $json.$Key
$value = $null
if ($entry.PSObject.Properties.Name -contains $locale) { $value = $entry.$locale }
if (-not $value -and $entry.PSObject.Properties.Name -contains 'en') { $value = $entry.en }
if (-not $value) {
  Write-Error "No translation available for key: $Key (locale $locale)"
  exit 4
}

Write-Output $value
