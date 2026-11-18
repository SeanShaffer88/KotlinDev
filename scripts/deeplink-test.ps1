<#
.SYNOPSIS
  Test deep links / Android App Links from adb. PowerShell mirror of
  deeplink-test.sh — same options, same behaviour.
.EXAMPLE
  .\deeplink-test.ps1 -Url "https://example.com/item/42" -Package com.example.app
  .\deeplink-test.ps1 -Package com.example.app -ListLinks
  .\deeplink-test.ps1 -Package com.example.app -ListLinks -ReVerify
.NOTES
  Requirements: adb on PATH; a connected device/emulator; the app installed.
  -ListLinks runs `pm get-app-links` plus the domain-verify dumpsys.
  -ReVerify runs `pm verify-app-links --re-verify` for the package.
  For https App Links to open the app directly, the domain must serve a valid
  assetlinks.json and the app must declare the intent-filter with
  android:autoVerify="true" — verification state is what -ListLinks shows.
#>
[CmdletBinding()]
param(
  [string]$Url = "",
  [string]$Package = "",
  [switch]$ListLinks,
  [switch]$ReVerify,
  [string]$Serial = "",
  [switch]$Help
)
$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { throw "adb not found on PATH." }
$AdbArgs = @(); if ($Serial) { $AdbArgs = @("-s", $Serial) }

if ($ReVerify) {
  if (-not $Package) { throw "-ReVerify needs -Package." }
  Write-Host ">> Re-running App Links verification for $Package ..."
  & adb @AdbArgs shell pm verify-app-links --re-verify $Package
}

if ($ListLinks) {
  if (-not $Package) { throw "-ListLinks needs -Package." }
  Write-Host ">> App Links state for ${Package}:"
  & adb @AdbArgs shell pm get-app-links $Package
  Write-Host ""
  Write-Host ">> Domain verification detail:"
  & adb @AdbArgs shell dumpsys package domain-preference $Package
  exit 0
}

if (-not $Url) { throw "-Url is required (or use -ListLinks)." }
Write-Host ">> Firing VIEW intent for: $Url"
if ($Package) {
  & adb @AdbArgs shell am start -a android.intent.action.VIEW -d $Url -p $Package
} else {
  & adb @AdbArgs shell am start -a android.intent.action.VIEW -d $Url
}
Write-Host "Done. Watch the device: the app (or a chooser) should now be in front."
