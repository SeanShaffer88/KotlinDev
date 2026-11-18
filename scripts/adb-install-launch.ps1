<#
.SYNOPSIS
  Build (debug), install, and launch an Android app. PowerShell mirror of
  adb-install-launch.sh — same options, same behaviour.
.EXAMPLE
  .\adb-install-launch.ps1 -Package com.example.app
  .\adb-install-launch.ps1 -Package com.example.app -Apk .\app-debug.apk
  .\adb-install-launch.ps1 -Package com.example.app -Activity com.example.app.MainActivity
.NOTES
  Requirements: adb on PATH; Gradle wrapper in the project (unless -Apk or
  -SkipBuild); a connected device or running emulator.
  Without -Activity the app is launched via monkey (launcher intent), which
  works for any app with a launcher activity without knowing its class name.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Package,
  [string]$Project = ".",
  [string]$Apk = "",
  [switch]$SkipBuild,
  [string]$Activity = "",
  [string]$Serial = "",
  [switch]$Help
)
$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { throw "adb not found on PATH." }
$AdbArgs = @(); if ($Serial) { $AdbArgs = @("-s", $Serial) }

if (-not $Apk -and -not $SkipBuild) {
  Write-Host ">> Building debug APK in $Project ..."
  Push-Location $Project
  try { & .\gradlew.bat assembleDebug; if ($LASTEXITCODE -ne 0) { throw "Gradle build failed." } }
  finally { Pop-Location }
}
if (-not $Apk) {
  $found = Get-ChildItem -Path $Project -Recurse -Filter *.apk -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "outputs\\apk\\debug" } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($found) { $Apk = $found.FullName }
}
if (-not $Apk -or -not (Test-Path $Apk)) { throw "No debug APK found. Build first or pass -Apk." }

Write-Host ">> Installing $Apk ..."
& adb @AdbArgs install -r $Apk
if ($LASTEXITCODE -ne 0) { throw "adb install failed." }

if ($Activity) {
  Write-Host ">> Launching $Package/$Activity ..."
  & adb @AdbArgs shell am start -n "$Package/$Activity"
} else {
  Write-Host ">> Launching $Package (launcher intent via monkey) ..."
  & adb @AdbArgs shell monkey -p $Package -c android.intent.category.LAUNCHER 1
}
Write-Host "Done."
