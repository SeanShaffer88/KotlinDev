<#
.SYNOPSIS
  Sanity-check an Android App Bundle (.aab) the way Play will consume it:
  build a universal APK with bundletool and install it. PowerShell mirror of
  play-bundle-verify.sh — same options, same behaviour.
.EXAMPLE
  .\play-bundle-verify.ps1 -Aab .\app-release.aab -Bundletool .\bundletool.jar
  .\play-bundle-verify.ps1 -Aab .\app-release.aab   # prints the exact commands
.NOTES
  Requirements: java on PATH and adb on PATH (install step); a connected
  device/emulator for the install step. bundletool jar:
  https://github.com/google/bundletool/releases
  Without -Bundletool, the script prints the exact commands to run yourself
  and exits without doing anything. Signing: a universal APK built from a
  release AAB needs the AAB's signing key to install — use the printed manual
  commands with your keystore if the debug-key fallback fails. This script
  never asks for or stores keystore passwords.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Aab,
  [string]$Bundletool = "",
  [string]$Out = ".\bundle-verify",
  [switch]$NoInstall,
  [string]$Serial = "",
  [switch]$Help
)
$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }
if (-not (Test-Path $Aab)) { throw "-Aab must point to an existing .aab file." }

if (-not $Bundletool) {
  Write-Host @"
bundletool jar not given — nothing was run. To verify $Aab yourself:

  # 1. Download bundletool (single jar) from:
  #    https://github.com/google/bundletool/releases
  # 2. Build a universal APK set from the bundle:
  java -jar bundletool.jar build-apks --bundle=$Aab ``
      --output=$Out\app.apks --mode=universal
  #    (signed release AAB? add: --ks=upload-keystore.jks --ks-key-alias=upload ``
  #     --ks-pass=pass:YOUR_PASSWORD --key-pass=pass:YOUR_PASSWORD)
  # 3. Extract and install the universal APK:
  Expand-Archive / jar: the .apks file is a zip containing universal.apk
  adb install -r $Out\universal.apk

Or re-run this script with -Bundletool <path-to-jar>.
"@
  exit 0
}

if (-not (Test-Path $Bundletool)) { throw "bundletool jar not found: $Bundletool" }
if (-not (Get-Command java -ErrorAction SilentlyContinue)) { throw "java not found on PATH." }
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$apks = Join-Path $Out "app.apks"

Write-Host ">> Building universal APK set from $Aab ..."
& java -jar $Bundletool build-apks --bundle=$Aab --output=$apks --mode=universal --overwrite
if ($LASTEXITCODE -ne 0) { throw "bundletool build-apks failed." }

Write-Host ">> Extracting universal.apk ..."
# .apks is a zip; System.IO.Compression extracts the one entry we need.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $apks))
try {
  $entry = $zip.Entries | Where-Object { $_.FullName -eq "universal.apk" } | Select-Object -First 1
  if (-not $entry) { throw "universal.apk not produced." }
  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path (Resolve-Path $Out) "universal.apk"), $true)
} finally { $zip.Dispose() }
$universal = Join-Path $Out "universal.apk"
Write-Host ">> Universal APK: $universal ($([math]::Round((Get-Item $universal).Length / 1MB, 2)) MB)"

if (-not $NoInstall) {
  if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { throw "adb not found on PATH." }
  $AdbArgs = @(); if ($Serial) { $AdbArgs = @("-s", $Serial) }
  Write-Host ">> Installing universal APK ..."
  & adb @AdbArgs install -r $universal
  if ($LASTEXITCODE -ne 0) { throw "adb install failed." }
  Write-Host "Done: bundle verified and installed. Launch the app and smoke-test it."
} else {
  Write-Host "Done: bundle verified (install skipped with -NoInstall)."
}
