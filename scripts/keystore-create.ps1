<#
.SYNOPSIS
  Guided creation of a release (upload) keystore with keytool, plus a
  password-free keystore.properties template. PowerShell mirror of
  keystore-create.sh — same prompts, same safety rules.
.EXAMPLE
  .\keystore-create.ps1
  .\keystore-create.ps1 -Output .\keys\upload-keystore.jks -Alias upload
.NOTES
  Requirements: keytool on PATH (ships with the JDK).
  SAFETY:
  * Passwords are typed at hidden prompts and passed to keytool through
    environment variables; they are never echoed and never written to disk
    by this script. The keystore.properties it writes has PLACEHOLDERS only.
  * If you lose this keystore or its password and you are NOT enrolled in
    Play App Signing, you can never update your app again.
  * Back the keystore up in at least two safe places OUTSIDE the repo, and
    NEVER commit it (add *.jks / *.keystore and keystore.properties to
    .gitignore). Refuses to overwrite an existing keystore file.
#>
[CmdletBinding()]
param(
  [string]$Output = ".\upload-keystore.jks",
  [string]$Alias = "upload",
  [int]$Validity = 10000,
  [switch]$Help
)
$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }
if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) { throw "keytool not found on PATH (install a JDK)." }
if (Test-Path $Output) { throw "$Output already exists. Refusing to overwrite a keystore." }

$cn      = Read-Host "Your name (CN, e.g. Ada Lovelace)"
$org     = Read-Host "Organization (O, optional)"
$city    = Read-Host "City (L, optional)"
$state   = Read-Host "State/Province (ST, optional)"
$country = Read-Host "Country code (C, two letters, e.g. US)"
$dname = "CN=$cn"
if ($org)     { $dname += ", O=$org" }
if ($city)    { $dname += ", L=$city" }
if ($state)   { $dname += ", ST=$state" }
if ($country) { $dname += ", C=$country" }

$sec1 = Read-Host "Keystore password (min 6 chars, hidden)" -AsSecureString
$sec2 = Read-Host "Repeat keystore password" -AsSecureString
$pass1 = [System.Net.NetworkCredential]::new("", $sec1).Password
$pass2 = [System.Net.NetworkCredential]::new("", $sec2).Password
if ($pass1 -ne $pass2) { throw "Passwords do not match." }
if ($pass1.Length -lt 6) { throw "Password must be at least 6 characters." }

# keytool reads passwords from the environment with :env — nothing is echoed,
# printed, or stored by this script beyond the live process environment.
$env:KS_STORE_PASS = $pass1; $env:KS_KEY_PASS = $pass1
try {
  & keytool -genkeypair -v -keystore $Output -storetype PKCS12 `
    "-storepass:env" KS_STORE_PASS "-keypass:env" KS_KEY_PASS `
    -alias $Alias -keyalg RSA -keysize 2048 -validity $Validity -dname $dname
  if ($LASTEXITCODE -ne 0) { throw "keytool failed." }
} finally {
  Remove-Item Env:KS_STORE_PASS, Env:KS_KEY_PASS -ErrorAction SilentlyContinue
  $pass1 = $null; $pass2 = $null
}

$dir = Split-Path -Parent $Output; if (-not $dir) { $dir = "." }
$props = Join-Path $dir "keystore.properties"
if (-not (Test-Path $props)) {
  @"
# keystore.properties — fill in locally. NEVER commit this file with real
# passwords in it, and never commit the keystore itself.
storeFile=$(Split-Path -Leaf $Output)
storePassword=REPLACE_ME_LOCAL_ONLY
keyAlias=$Alias
keyPassword=REPLACE_ME_LOCAL_ONLY
"@ | Set-Content -Path $props -Encoding UTF8
  Write-Host ">> Wrote template $props (placeholders only, no real passwords)."
}

Write-Host ""
Write-Host "Done: $Output (alias: $Alias)"
Write-Host "NOW: 1) Back this keystore up in two safe places OUTSIDE the repo."
Write-Host "     2) Add '*.jks', '*.keystore' and 'keystore.properties' to .gitignore."
Write-Host "     3) Keep the password in a password manager — it cannot be recovered."
