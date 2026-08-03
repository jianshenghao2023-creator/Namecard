param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
    [string]$OutputDir = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path "portable_packages")
)

$ErrorActionPreference = "Stop"

$project = Resolve-Path -LiteralPath $ProjectRoot
$ProjectRoot = $project.Path
$exePath = Join-Path $ProjectRoot "tools\namecard_updater\dist\NamecardUpdater.exe"
if (!(Test-Path -LiteralPath $exePath -PathType Leaf)) {
    throw "NamecardUpdater.exe not found. Build it first: tools\namecard_updater\build_exe.ps1"
}

$stamp = Get-Date -Format "yyyyMMdd_HHmm"
$packageName = "NamecardPortable_$stamp"
$packageRoot = Join-Path $OutputDir $packageName
$zipPath = Join-Path $OutputDir "$packageName.zip"

New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

function Copy-RelativePath {
    param([string]$RelativePath)
    $src = Join-Path $ProjectRoot $RelativePath
    if (!(Test-Path -LiteralPath $src)) {
        Write-Host "Skip missing: $RelativePath"
        return
    }
    $dst = Join-Path $packageRoot $RelativePath
    $parent = Split-Path -Parent $dst
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
}

$directories = @(
    ".git",
    ".github",
    "mobile_search",
    "mobile_data"
)

foreach ($dir in $directories) {
    Copy-RelativePath $dir
}

$files = @(
    ".gitignore",
    "README.md",
    "build_mobile_search.ps1",
    "namecard_contacts_template_v1.csv",
    "namecard_contacts_template_v1.xlsx",
    "namecard_contacts_enriched_v1.csv",
    "namecard_contacts_enriched_v1.xlsx",
    "company_classification_v1.csv",
    "company_classification_v1.xlsx",
    "company_classification_verified_v1.csv",
    "company_classification_verified_v1.xlsx",
    "tools\namecard_updater\README.md",
    "tools\namecard_updater\build_exe.ps1",
    "tools\namecard_updater\namecard_updater.py",
    "tools\namecard_updater\portable_readme_template.md",
    "tools\namecard_updater\requirements.txt",
    "tools\namecard_updater\package_portable.ps1"
)

foreach ($file in $files) {
    Copy-RelativePath $file
}

Get-ChildItem -LiteralPath $ProjectRoot -File -Filter "*.md" | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $packageRoot $_.Name) -Force
}

Copy-Item -LiteralPath $exePath -Destination (Join-Path $packageRoot "NamecardUpdater.exe") -Force

$contactsDataPath = Join-Path $ProjectRoot "mobile_search\contacts-data.json"
$contacts = ""
$companies = ""
$version = ""
if (Test-Path -LiteralPath $contactsDataPath -PathType Leaf) {
    $json = Get-Content -LiteralPath $contactsDataPath -Encoding UTF8 | ConvertFrom-Json
    $contacts = [string]$json.meta.contactCount
    $companies = [string]$json.meta.companyCount
    $version = [string]$json.meta.dataVersion
}

$startCmd = @"
@echo off
chcp 65001 >nul
cd /d "%~dp0"
start "" "%~dp0NamecardUpdater.exe"
"@
[System.IO.File]::WriteAllText((Join-Path $packageRoot "Start_NamecardUpdater.cmd"), $startCmd, [System.Text.UTF8Encoding]::new($false))

$ocrCmd = @"
@echo off
chcp 65001 >nul
echo Installing free OCR: UB Mannheim Tesseract OCR
winget install --id UB-Mannheim.TesseractOCR -e
echo.
echo After installation, reopen NamecardUpdater or click "Detect OCR" in the app.
pause
"@
[System.IO.File]::WriteAllText((Join-Path $packageRoot "Install_Free_OCR_Tesseract.cmd"), $ocrCmd, [System.Text.UTF8Encoding]::new($false))

$gitCmd = @"
@echo off
chcp 65001 >nul
echo Installing Git for Windows
winget install --id Git.Git -e
echo.
echo After installation, reopen NamecardUpdater.
pause
"@
[System.IO.File]::WriteAllText((Join-Path $packageRoot "Install_Git.cmd"), $gitCmd, [System.Text.UTF8Encoding]::new($false))

$templatePath = Join-Path $PSScriptRoot "portable_readme_template.md"
$readme = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$readme = $readme.Replace("__CONTACTS__", $contacts).Replace("__COMPANIES__", $companies).Replace("__VERSION__", $version)
[System.IO.File]::WriteAllText((Join-Path $packageRoot "README_FIRST.md"), $readme, [System.Text.UTF8Encoding]::new($false))

if (Test-Path -LiteralPath $zipPath -PathType Leaf) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -LiteralPath $packageRoot -DestinationPath $zipPath -Force

Write-Host "Portable folder: $packageRoot"
Write-Host "Portable zip:    $zipPath"
Write-Host "Contacts:        $contacts"
Write-Host "Companies:       $companies"
Write-Host "Version:         $version"
