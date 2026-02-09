[CmdletBinding()]
param(
    [ValidateSet('Install', 'Uninstall')]
    [string]$Action = 'Install',
    [switch]$Silent,
    [switch]$DryRun,
    [switch]$SkipElevation,
    [string]$Driver1Path,
    [string]$Driver2Path,
    [string]$Driver1Url = 'https://github.com/supermarsx/magickeyboard/releases/latest/download/magickeyboard1_AppleKeyboardInstaller64.exe',
    [string]$Driver2Url = 'https://github.com/supermarsx/magickeyboard/releases/latest/download/magickeyboard2_AppleKeyboardInstaller64.exe',
    [string]$DriverArgs = '/S',
    [string]$LayoutsScriptPath
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

if (-not $LayoutsScriptPath) {
    $LayoutsScriptPath = Join-Path (Split-Path -Parent $scriptDir) 'MagicKeyboard.ps1'
}

function Write-Status {
    param([string]$Message)
    if (-not $Silent) { Write-Host $Message }
}

function Test-IsElevated {
    if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    return $true
}

function Invoke-ElevatedSelf {
    $self = $MyInvocation.MyCommand.Definition
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$self`"", '-Action', $Action)
    if ($Silent) { $argList += '-Silent' }
    if ($DryRun) { $argList += '-DryRun' }
    if ($Driver1Path) { $argList += @('-Driver1Path', "`"$Driver1Path`"") }
    if ($Driver2Path) { $argList += @('-Driver2Path', "`"$Driver2Path`"") }
    if ($Driver1Url) { $argList += @('-Driver1Url', "`"$Driver1Url`"") }
    if ($Driver2Url) { $argList += @('-Driver2Url', "`"$Driver2Url`"") }
    if ($DriverArgs) { $argList += @('-DriverArgs', "`"$DriverArgs`"") }
    if ($LayoutsScriptPath) { $argList += @('-LayoutsScriptPath', "`"$LayoutsScriptPath`"") }

    $argString = $argList -join ' '
    $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $argString -Verb RunAs -PassThru -Wait
    return $proc.ExitCode
}

function Resolve-DriverInstaller {
    param(
        [string]$Name,
        [string]$ExplicitPath,
        [string]$Url
    )

    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath)) {
            throw "$Name installer path not found: $ExplicitPath"
        }
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }

    $fileName = Split-Path -Leaf $Url
    $localPath = Join-Path $scriptDir $fileName
    if (Test-Path -LiteralPath $localPath) {
        return $localPath
    }

    $downloadPath = Join-Path $env:TEMP $fileName
    Write-Status "Downloading $Name installer: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $downloadPath
    return $downloadPath
}

function Invoke-DriverInstaller {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Arguments
    )

    if ($DryRun) {
        Write-Status "DRYRUN ${Name}: `"$Path`" $Arguments"
        return $true
    }

    Write-Status "Running $Name installer silently..."
    $proc = Start-Process -FilePath $Path -ArgumentList $Arguments -PassThru -Wait
    if ($proc.ExitCode -in @(0, 1641, 3010)) {
        Write-Status "$Name installer completed with code $($proc.ExitCode)"
        return $true
    }

    Write-Status "$Name installer failed with code $($proc.ExitCode)"
    return $false
}

if (-not $SkipElevation -and -not $DryRun -and -not (Test-IsElevated)) {
    $code = Invoke-ElevatedSelf
    exit $code
}

if (-not (Test-Path -LiteralPath $LayoutsScriptPath)) {
    throw "Layouts installer script not found: $LayoutsScriptPath"
}

if ($Action -eq 'Install') {
    $driver1 = Resolve-DriverInstaller -Name 'MagicKeyboard1' -ExplicitPath $Driver1Path -Url $Driver1Url
    $driver2 = Resolve-DriverInstaller -Name 'MagicKeyboard2_3' -ExplicitPath $Driver2Path -Url $Driver2Url

    $ok1 = Invoke-DriverInstaller -Name 'MagicKeyboard1' -Path $driver1 -Arguments $DriverArgs
    $ok2 = Invoke-DriverInstaller -Name 'MagicKeyboard2_3' -Path $driver2 -Arguments $DriverArgs

    if (-not $ok1 -and -not $ok2) {
        throw 'Both driver installers failed.'
    }

    Write-Status 'Running layout installer silently...'
    $layoutParams = @{
        Action = 'Install'
        NoLogo = $true
    }
    if ($Silent) { $layoutParams.Quiet = $true }
    if ($DryRun) { $layoutParams.DryRun = $true }
    & $LayoutsScriptPath @layoutParams
    exit $LASTEXITCODE
}

Write-Status 'Running layout uninstaller silently...'
$uninstallParams = @{
    Action = 'Uninstall'
    NoLogo = $true
}
if ($Silent) { $uninstallParams.Quiet = $true }
if ($DryRun) { $uninstallParams.DryRun = $true }
& $LayoutsScriptPath @uninstallParams
exit $LASTEXITCODE
