<#
.SYNOPSIS
  Everyday operations on one installed app. PowerShell mirror of
  adb-app-ops.sh — same operations, same safety rules.
.EXAMPLE
  .\adb-app-ops.ps1 -Package com.example.app -ForceStop
  .\adb-app-ops.ps1 -Package com.example.app -Grant android.permission.CAMERA
  .\adb-app-ops.ps1 -Package com.example.app -Reset
.NOTES
  Requirements: adb on PATH; a connected device/emulator; the app installed.
  -Reset is DESTRUCTIVE (pm clear: all app data) and asks you to type the
  package ID to confirm before doing anything.
  Cache note: Android has no reliable adb command that clears ONLY an app's
  cache without touching its data; `pm clear` wipes both, so this script does
  not offer a fake "clear cache only" operation.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Package,
  [switch]$ForceStop,
  [string[]]$Grant = @(),
  [string[]]$Revoke = @(),
  [switch]$Settings,
  [switch]$Reset,
  [string]$Serial = "",
  [switch]$Help
)
$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }
if (-not $ForceStop -and -not $Settings -and -not $Reset -and $Grant.Count -eq 0 -and $Revoke.Count -eq 0) {
  throw "Choose at least one operation: -ForceStop, -Grant, -Revoke, -Settings, or -Reset."
}
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { throw "adb not found on PATH." }
$AdbArgs = @(); if ($Serial) { $AdbArgs = @("-s", $Serial) }

if ($Reset) {
  Write-Warning "RESET deletes ALL data for $Package (accounts, saves, files)."
  $confirm = Read-Host "Type the package ID to confirm"
  if ($confirm -ne $Package) { throw "Aborted: confirmation did not match." }
}

if ($ForceStop) { Write-Host ">> Force-stopping $Package"; & adb @AdbArgs shell am force-stop $Package }
foreach ($p in $Grant)  { Write-Host ">> Granting $p";  & adb @AdbArgs shell pm grant  $Package $p }
foreach ($p in $Revoke) { Write-Host ">> Revoking $p"; & adb @AdbArgs shell pm revoke $Package $p }
if ($Settings) {
  Write-Host ">> Opening app settings for $Package"
  & adb @AdbArgs shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:$Package"
}
if ($Reset) { Write-Host ">> Clearing all data for $Package"; & adb @AdbArgs shell pm clear $Package }
Write-Host "Done."
