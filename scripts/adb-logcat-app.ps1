<#
.SYNOPSIS
  Stream logcat filtered to one app's process. PowerShell mirror of
  adb-logcat-app.sh — same options, same behaviour.
.EXAMPLE
  .\adb-logcat-app.ps1 -Package com.example.app
  .\adb-logcat-app.ps1 -Package com.example.app -Clear -Save .\log.txt
.NOTES
  Requirements: adb on PATH; a connected device/emulator; the app installed
  and running (its PID is read with pidof). Stop with Ctrl+C.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Package,
  [switch]$Clear,
  [string]$Save = "",
  [string]$Serial = "",
  [switch]$Help
)
$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { throw "adb not found on PATH." }
$AdbArgs = @(); if ($Serial) { $AdbArgs = @("-s", $Serial) }

if ($Clear) { & adb @AdbArgs logcat -c; Write-Host ">> Log buffer cleared." }

$pidText = (& adb @AdbArgs shell pidof $Package) -join " "
$appPid = ($pidText.Trim() -split "\s+")[0]
if (-not $appPid) {
  throw "$Package is not running (pidof returned nothing). Start the app first, then re-run."
}
Write-Host ">> Streaming logcat for $Package (pid $appPid). Ctrl+C to stop."
if ($Save) {
  & adb @AdbArgs logcat --pid=$appPid | Tee-Object -FilePath $Save
} else {
  & adb @AdbArgs logcat --pid=$appPid
}
