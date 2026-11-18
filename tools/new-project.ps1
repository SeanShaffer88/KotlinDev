# new-project.ps1 — scaffold a minimal Compose app from templates/compose-app.
#
# Usage: .\new-project.ps1 -ProjectName MyApp -PackageId com.example.myapp [-Destination .]
#
# Copies templates/compose-app into <Destination>\<ProjectName>, renames the
# com.example.app package folders to the requested package id, and substitutes
# the placeholders in settings.gradle.kts, app/build.gradle.kts and
# MainActivity.kt. PowerShell 5.1+; no network access.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectName,
    [Parameter(Mandatory = $true)][string]$PackageId,
    [string]$Destination = "."
)

$ErrorActionPreference = "Stop"

if ($PackageId -notmatch '\.') {
    throw "Package id must contain a dot, e.g. com.example.myapp"
}

$TemplateDir = Join-Path $PSScriptRoot "..\templates\compose-app"
$TemplateDir = (Resolve-Path $TemplateDir).Path
$Dest = Join-Path $Destination $ProjectName

if (Test-Path $Dest) {
    throw "Destination already exists: $Dest"
}

Copy-Item -Recurse $TemplateDir $Dest

# Move the template package (com\example\app) to the requested package path.
$JavaRoot = Join-Path $Dest "app\src\main\java"
$OldPkgDir = Join-Path $JavaRoot "com\example\app"
$NewPkgDir = Join-Path $JavaRoot ($PackageId -replace '\.', '\')
if ($OldPkgDir -ne $NewPkgDir) {
    New-Item -ItemType Directory -Force (Split-Path $NewPkgDir) | Out-Null
    Move-Item $OldPkgDir $NewPkgDir
    Remove-Item (Join-Path $JavaRoot "com\example") -ErrorAction SilentlyContinue
}

# Substitute placeholders.
Get-ChildItem $Dest -Recurse -File -Include *.kts, *.kt, *.xml, *.toml |
    ForEach-Object {
        $text = Get-Content $_.FullName -Raw
        $text = $text -replace [regex]::Escape("com.example.app"), $PackageId
        $text = $text -replace "ComposeApp", $ProjectName
        Set-Content $_.FullName $text -NoNewline
    }

Write-Host "Created $Dest"
Write-Host "  package: $PackageId"
Write-Host "Open the folder in Android Studio, let Gradle sync, then run the app."
Write-Host "Validate any time with: python tools/check-project.py `"$Dest`""
