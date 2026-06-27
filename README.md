# 名片查询在线同步版

这个文件夹包含查询工具和在线同步数据。部署到 HTTPS 地址后，手机联网打开时会自动下载 `contacts-data.json`，保存到手机本地；之后没有网络也可以查询。

## GitHub Pages 部署

这个项目现在使用 GitHub Actions 部署到 GitHub Pages。仓库地址：

```text
https://github.com/jianshenghao2023-creator/Namecard
```

部署方式：

1. 仓库 Settings -> Pages -> Build and deployment，Source 选择 `GitHub Actions`。如果暂时看不到 Source 选项，可以先到 Actions 运行部署工作流，工作流会尝试自动启用 Pages。
2. 把项目推送到仓库的 `main` 分支。
3. GitHub Actions 会自动发布 `mobile_search` 文件夹。
4. 发布后访问：

```text
https://jianshenghao2023-creator.github.io/Namecard/
```

## 首次使用

1. iPhone 用 Safari 打开 GitHub Pages 地址，并添加到主屏幕。
2. 第一次打开时保持联网，等待页面显示联系人数量。
3. 之后即使没有网络，也可以使用上次保存的数据查询。

## 更新数据

1. 先更新上一级目录里的 `namecard_contacts_enriched_v1.csv`。
2. 在项目目录运行 `.\build_mobile_search.ps1`。
3. 提交并推送 `mobile_search` 文件夹里的更新内容到 GitHub。
4. GitHub Actions 发布完成后，iPhone 下次联网打开时会自动同步新版数据。

页面里的“导入/更新”按钮仍可作为备用：如果在线同步不方便，也可以手动选择 `mobile_data/namecard_contacts_data.json`。

## 本地预览

```powershell
cd mobile_search
.\serve.ps1
```

然后按脚本输出的本地地址打开。
