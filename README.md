<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/header-dark.svg">
  <img src="docs/assets/header-light.svg" alt="CC#Skin — Claude 的字体、配色与 Mods 工具" width="100%">
</picture>

<p align="center">调整 Claude 的字体与配色，管理 Claude Code 的 Mods。</p>
<p align="center">
  <a href="https://github.com/Orxooo/CCSkin/releases/download/v1.1.0/CCSkin-1.1.0-macOS-arm64.zip"><b>下载 macOS 版</b></a>　·　
  <a href="README.en.md">English</a>　·　
  <a href="CHANGELOG.md">更新记录</a>
</p>
<p align="center"><sub>macOS 26+ · Apple Silicon · 1.1.0</sub></p>

<img src="docs/assets/fonts.png" alt="CC#Skin 字体与阅读排版设置" width="100%">

## 功能

- **字体与排版**：中英文、界面和代码分别设置，支持字号、行距和阅读宽度。
- **配色与主题**：调整浅色背景和深色主题，保存组合，或导入他人的主题。
- **Mods**：内置 4 个来源、156 项目录，支持搜索、筛选、排序、添加仓库与插件管理。

<details>
<summary>查看 Mods 界面</summary>
<br>
<img src="docs/assets/mods.png" alt="Mods 来源、筛选与安装管理" width="100%">
</details>

## 安装

1. 下载 ZIP，解压后将 `CC#Skin.app` 放入「应用程序」。
2. 打开应用，在「概览」检测 App 管理权限。
3. 选择目标 Claude，调整样式后，退出 Claude 再应用。

安装包已签名，未经 Apple 公证。首次打开、SHA-256 校验和升级说明见[使用指南](docs/USAGE.md)。

## 使用

**外观**：修改前自动备份；撤销时退出 Claude，在「更多操作」选择「还原应用」。Claude 更新后需重新检查兼容性。

**Mods**：需要 Claude Code CLI 2.1.287+。选好操作后统一应用，再在 Code 会话运行 `/reload-plugins` 或重开会话。第三方 Mods 会在本机执行代码，安装前请查看源码。[来源与排行说明](docs/MODS.md)

## 文档

[使用指南](docs/USAGE.md) · [Mods](docs/MODS.md) · [构建与 CLI](docs/DEVELOPMENT.md) · [验证记录](docs/VERIFICATION.md) · [参与开发](CONTRIBUTING.md)

---

[GPL-3.0-only](LICENSE) · © 2026 Orxooo · 与 Anthropic 无隶属关系。[项目声明](NOTICE)
