<#
.SYNOPSIS
  List Android Virtual Devices (AVDs) and boot one, waiting until Android
  has fully started. PowerShell mirror of emulator-boot.sh.
.EXAMPLE
  .\emulator-boot.ps1 -List
  .\emulator-boot.ps1 -Avd Pixel_8_API_36
  .\emulator-boot.ps1 -Avd Pixel_8_API_36 -Headless -Cold
.NOTES
  Requirements: Android SDK emulator on PATH or ANDROID_HOME / ANDROID_SDK_ROOT
  set; adb on PATH; at least one AVD created in Android Studio (AVD Manager).
  Snapshots: -Snapshot NAME loads a named snapshot; -Cold ignores snapshots.
#>
[CmdletBinding()]
param(
  [switch]$List,
  [string]$Avd = "",
  [switch]$Headless,
  [string]$Snapshot = "",
  [switch]$Cold,
  [int]$Timeout = 300,
  [switch]$Help
)
$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }

$emulator = $null
if (Get-Command emulator -ErrorAction SilentlyContinue) { $emulator = (Get-Command emulator).Source }
elseif ($env:ANDROID_HOME -and (Test-Path "$env:ANDROID_HOME\emulator\emulator.exe")) { $emulator = "$env:ANDROID_HOME\emulator\emulator.exe" }
elseif ($env:ANDROID_SDK_ROOT -and (Test-Path "$env:ANDROID_SDK_ROOT\emulator\emulator.exe")) { $emulator = "$env:ANDROID_SDK_ROOT\emulator\emulator.exe" }
else { throw "Emulator binary not found (PATH, ANDROID_HOME, ANDROID_SDK_ROOT all checked)." }

if ($List) { & $emulator -list-avds; exit 0 }
if (-not $Avd) { throw "-Avd is required (or use -List)." }
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { throw "adb not found on PATH." }

$emuArgs = @("-avd", $Avd)
if ($Headless) { $emuArgs += "-no-window" }
if ($Snapshot) { $emuArgs += @("-snapshot", $Snapshot) }
if ($Cold) { $emuArgs += "-no-snapshot-load" }

Write-Host ">> Booting AVD '$Avd' in the background..."
Start-Process -FilePath $emulator -ArgumentList $emuArgs | Out-Null

Write-Host ">> Waiting for a device..."
& adb wait-for-device
Write-Host ">> Waiting for boot to complete (timeout ${Timeout}s)..."
$elapsed = 0
while (((& adb shell getprop sys.boot_completed) -join "").Trim() -ne "1") {
  Start-Sleep -Seconds 5; $elapsed += 5
  if ($elapsed -ge $Timeout) { throw "Emulator did not finish booting within ${Timeout}s." }
}
& adb shell wm dismiss-keyguard 2>$null | Out-Null
Write-Host "Done: '$Avd' is booted and ready."
