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
    "项目使用说明书.md",
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
    "tools\namecard_updater\requirements.txt",
    "tools\namecard_updater\package_portable.ps1"
)

foreach ($file in $files) {
    Copy-RelativePath $file
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

$readme = @'
# NamecardPortable 使用说明

这是名片系统的便携程序包。解压后，整个文件夹就是一个可继续维护和发布的项目目录。

## 快速使用

1. 把整个文件夹复制到其它 Windows 电脑，例如：

```text
D:\NamecardPortable
```

2. 双击：

```text
Start_NamecardUpdater.cmd
```

也可以直接双击：

```text
NamecardUpdater.exe
```

3. 程序启动后，项目目录应自动识别为当前文件夹。

4. 选择新增 PDF，点击“识别 PDF”。

5. 检查“重复检查”列，确认联系人字段。

6. 点击“写入并发布”。

## 这个包里包含什么

- `NamecardUpdater.exe`：新增名片、查重、生成网页数据、发布 GitHub Pages 的主程序。
- 当前联系人和公司主数据：CSV/XLSX。
- `mobile_search`：GitHub Pages 发布用网页目录。
- `mobile_data`：备用手机导入数据。
- `.git` 和 `.github`：Git 仓库和自动发布配置。
- 安装脚本：
  - `Install_Free_OCR_Tesseract.cmd`
  - `Install_Git.cmd`

当前数据：

```text
contacts = __CONTACTS__
companies = __COMPANIES__
version = __VERSION__
```

## 其它电脑需要什么

### 必需

- Windows 10/11。
- Git for Windows：用于提交和推送 GitHub Pages。
- GitHub 登录权限：第一次 push 时可能会弹出浏览器登录。

如果电脑没有 Git，双击：

```text
Install_Git.cmd
```

### 推荐

- 免费 OCR：Tesseract OCR。

如果电脑没有 OCR，程序仍然可以手工录入；安装 OCR 后会自动预填识别结果。

安装 OCR：

```text
Install_Free_OCR_Tesseract.cmd
```

## 关于历史 PDF

为了减小包体积并减少隐私风险，本包没有包含历史扫描 PDF 和 `_analysis` 分析图片。它们不是日常新增名片和发布网页所必需的。

新增名片时，选择你新扫描的 PDF 即可。

## 发布说明

本包保留了 Git 仓库信息，远端仓库是：

```text
https://github.com/jianshenghao2023-creator/Namecard
```

点击“写入并发布”后，程序会：

```text
更新本地 CSV/XLSX
生成 mobile_search\contacts-data.json
git commit
git push
GitHub Actions 自动发布到 gh-pages
```

如果第一次在新电脑上 push，Git 可能要求登录 GitHub。按浏览器提示完成授权即可。
'@
$readme = $readme.Replace("__CONTACTS__", $contacts).Replace("__COMPANIES__", $companies).Replace("__VERSION__", $version)
[System.IO.File]::WriteAllText((Join-Path $packageRoot "README_先读我.md"), $readme, [System.Text.UTF8Encoding]::new($false))

if (Test-Path -LiteralPath $zipPath -PathType Leaf) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -LiteralPath $packageRoot -DestinationPath $zipPath -Force

Write-Host "Portable folder: $packageRoot"
Write-Host "Portable zip:    $zipPath"
Write-Host "Contacts:        $contacts"
Write-Host "Companies:       $companies"
Write-Host "Version:         $version"
