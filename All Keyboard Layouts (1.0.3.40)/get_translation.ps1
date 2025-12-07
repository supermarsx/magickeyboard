param(
  [Parameter(Mandatory=$true)][string]$Key,
  [Parameter(Mandatory=$true)][string]$File,
  [Parameter(Mandatory=$false)][string]$Locale
)

try {
  $json = Get-Content -Raw -Path $File | ConvertFrom-Json -ErrorAction Stop
} catch {
  Write-Error "Could not load translations file: $File"
  exit 2
}

$localeRaw = if ($PSBoundParameters.ContainsKey('Locale') -and $Locale) { $Locale } else { (Get-UICulture).Name }

# Normalize locale string (drop codeset, convert underscores to hyphen)
$locale = ($localeRaw -replace '\..*$','' -replace '_','-')
if ($locale -match '-') {
  $parts = $locale -split '-'
  $lang = $parts[0]
  $region = $parts[1].ToUpper()
  $locale = "$lang-$region"
} else {
  $lang = $locale
}

$entry = $null
if ($json.PSObject.Properties.Name -contains $Key) { $entry = $json.$Key }

$value = $null
function Get-PropValue($obj, $propName) {
  if (-not $obj) { return $null }
  $prop = $obj.PSObject.Properties | Where-Object { $_.Name -eq $propName }
  if ($prop) { return $prop.Value }
  return $null
}

if ($entry -ne $null) {
  # Try exact locale (e.g. en-US), then language only (en), then fallback to en, then first available
  $value = Get-PropValue -obj $entry -propName $locale
  if (-not $value -and $lang) { $value = Get-PropValue -obj $entry -propName $lang }
  if (-not $value) { $value = Get-PropValue -obj $entry -propName 'en' }
  if (-not $value) {
    # If no 'en' but other translations exist, use the first available as a last resort
    $firstProp = $entry.PSObject.Properties | Select-Object -First 1 -ExpandProperty Name
    if ($firstProp) { $value = Get-PropValue -obj $entry -propName $firstProp }
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
