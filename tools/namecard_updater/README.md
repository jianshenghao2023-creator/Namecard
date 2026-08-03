# NamecardUpdater

免费本地名片新增工具，用于把新增 PDF 名片追加到本项目，并一键发布到 GitHub Pages。

## 功能

- 选择新增 PDF。
- 本地渲染扫描页。
- 自动切分候选名片区域。
- 使用免费本地 OCR 预填字段；没有 OCR 时也可手工录入。
- 人工确认联系人表格。
- 自动写回主 CSV/XLSX。
- 自动生成 `mobile_search/contacts-data.json`。
- 自动 `git commit` / `git push` 发布到 GitHub Pages。

## 免费 OCR

推荐安装 Tesseract OCR。程序会自动检测以下位置：

- 系统 PATH 中的 `tesseract.exe`
- `C:\Program Files\Tesseract-OCR\tesseract.exe`
- `C:\Program Files (x86)\Tesseract-OCR\tesseract.exe`

如果没有安装，可以在程序中点击“安装免费 OCR”，或手动执行：

```powershell
winget install --id UB-Mannheim.TesseractOCR -e
```

OCR 不是强制依赖。没有 OCR 时，程序仍可渲染 PDF、切分名片、人工录入并一键发布。

## 构建 EXE

构建时需要使用带 Tcl/Tk 的 Python。官方 Windows Python 通常自带；如果某个精简 Python 缺少 `tkinter`，脚本会停止并提示更换 Python。

```powershell
cd E:\namecard\tools\namecard_updater
.\build_exe.ps1
```

生成文件：

```text
E:\namecard\tools\namecard_updater\dist\NamecardUpdater.exe
```

## 使用

1. 双击 `NamecardUpdater.exe`。
2. 确认项目目录是 `E:\namecard`。
3. 选择新增 PDF。
4. 点击“识别 PDF”。
5. 在右侧编辑区逐条确认联系人。
6. 点击“写入并发布”。
7. 等待程序显示 GitHub Pages 检查结果。

## 注意

- 该工具不调用付费 API，不需要 OpenAI、Google、Azure 等付费密钥。
- 公司分类优先复用本项目已有分类；新公司会基于公司名、官网、行业标签进行免费规则推断，并标记为待确认或已核验。
- 如果 OCR 识别不准，以人工确认表格为准。
