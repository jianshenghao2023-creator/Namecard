# Namecard

名片查询静态网站。功能代码位于 `mobile_search`，部署方式为 GitHub Pages。

## 部署方式

仓库：

```text
https://github.com/jianshenghao2023-creator/Namecard
```

GitHub Pages 发布地址：

```text
https://jianshenghao2023-creator.github.io/Namecard/
```

部署方案：

- GitHub Actions 工作流：`.github/workflows/deploy-pages.yml`
- Pages 发布目录：`mobile_search`
- 数据文件：`mobile_search/contacts-data.json`

## GitHub 设置

进入仓库：

```text
Settings -> Pages -> Build and deployment
```

将 Source 设置为：

```text
GitHub Actions
```

之后推送到 `main` 分支时，GitHub Actions 会自动发布静态站。

如果你的 Pages 页面暂时看不到 Source 选项，也可以先到 `Actions` 里运行 `Deploy static site to GitHub Pages`。工作流里的 `actions/configure-pages` 已设置 `enablement: true`，会尝试自动启用 Pages。

## 首次推送

如果本地目录还没有初始化 Git，可以执行：

```powershell
git init
git branch -M main
git remote add origin https://github.com/jianshenghao2023-creator/Namecard.git
git add README.md .gitignore .github mobile_search build_mobile_search.ps1
git commit -m "Deploy static namecard site to GitHub Pages"
git push -u origin main
```

## 更新网站数据

1. 更新根目录的 `namecard_contacts_enriched_v1.csv`。
2. 运行：

```powershell
.\build_mobile_search.ps1
```

3. 提交并推送 `mobile_search/contacts-data.json` 的更新。
4. 等待 GitHub Actions 部署完成。

## 注意

`contacts-data.json` 是静态网站运行所需的数据文件，发布到 GitHub Pages 后可被访问。请确认仓库和 Pages 的可见性符合你的隐私要求。

根目录的 PDF、Excel、CSV、ZIP 和分析目录不参与静态网站部署，已通过 `.gitignore` 排除，避免误提交。
