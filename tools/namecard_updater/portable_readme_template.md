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
