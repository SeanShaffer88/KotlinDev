<#
.SYNOPSIS
  Capture a screenshot, and optionally a screen recording, from a connected
  device/emulator into a local folder. PowerShell mirror of adb-capture.sh.
.EXAMPLE
  .\adb-capture.ps1
  .\adb-capture.ps1 -Out .\shots -Record 30
.NOTES
  Requirements: adb on PATH; a connected, unlocked device/emulator.
  Files are timestamped: shot-YYYYmmdd-HHMMSS.png / rec-YYYYmmdd-HHMMSS.mp4
#>
[CmdletBinding()]
param(
  [string]$Out = ".\captures",
  [int]$Record = 0,
  [string]$Serial = "",
  [switch]$Help
)
$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { throw "adb not found on PATH." }
if ($Record -lt 0 -or $Record -gt 180) { throw "-Record must be between 0 and 180 seconds." }
$AdbArgs = @(); if ($Serial) { $AdbArgs = @("-s", $Serial) }
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$shot = Join-Path $Out "shot-$stamp.png"
Write-Host ">> Capturing screenshot -> $shot"
# exec-out streams raw PNG bytes; redirect at the cmd level to keep bytes intact.
$adbPath = (Get-Command adb).Source
$serialArg = if ($Serial) { "-s $Serial" } else { "" }
cmd /c "`"$adbPath`" $serialArg exec-out screencap -p > `"$shot`""
if ($LASTEXITCODE -ne 0) { throw "screencap failed." }

if ($Record -gt 0) {
  $rec = Join-Path $Out "rec-$stamp.mp4"
  $remote = "/sdcard/kotlindev-rec-$stamp.mp4"
  Write-Host ">> Recording ${Record}s -> $rec (keep the device on the screen you want)"
  & adb @AdbArgs shell screenrecord --time-limit $Record $remote
  & adb @AdbArgs pull $remote $rec | Out-Null
  & adb @AdbArgs shell rm -f $remote
}
Write-Host "Done. Captures in $Out"
