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

$entry = $null
if ($json.PSObject.Properties.Name -contains $Key) { $entry = $json.$Key }

$value = $null
if ($entry -ne $null) {
  if ($entry.PSObject.Properties.Name -contains $locale) { $value = $entry.$locale }
  if (-not $value -and $entry.PSObject.Properties.Name -contains 'en') { $value = $entry.en }
  if (-not $value) {
    # If no 'en' but other translations exist, use the first available as a last resort
    $firstProp = $entry.PSObject.Properties | Select-Object -First 1 -ExpandProperty Name
    if ($firstProp) { $value = $entry.$firstProp }
  }
}

if (-not $value) {
  # Fallback: attempt to produce a reasonable English-ish label from Key
  $friendly = $Key -replace '([A-Z])', ' $1' -replace '\s+$',''
  $friendly = $friendly.Trim()
  if ($friendly -notlike '*Apple*') { $friendly = "$friendly (Apple)" }
  $value = $friendly
}

Write-Output $value
