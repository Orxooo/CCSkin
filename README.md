<p align="center"><img src="gui/assets/ccskin-icon.png" alt="CC#Skin 图标" width="88"></p>
<h1 align="center">CC#Skin</h1>
<p align="center">Claude 桌面版的字体、外观与 Mods 管理工具。</p>
<p align="center">
<a href="https://github.com/Orxooo/ClaudeFont/releases/latest"><img src="https://img.shields.io/github/v/release/Orxooo/ClaudeFont" alt="最新版本"></a>
<img src="https://img.shields.io/badge/macOS-26%2B-lightgrey" alt="macOS 26+">
<a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--only-blue" alt="GPL-3.0-only"></a>
</p>

**[下载 CC#Skin 1.2.0](https://github.com/Orxooo/ClaudeFont/releases/download/v1.2.0/CCSkin-1.2.0-macOS-arm64.zip)** · [English](README.en.md) · [更新记录](CHANGELOG.md) · [问题反馈](https://github.com/Orxooo/ClaudeFont/issues/new/choose)

当前发行版本 **1.2.0（构建 7）**。适用于 **macOS 26+ 的 Apple Silicon Mac**；Mods 管理另需 Claude Code 官方 CLI **2.1.287+**。

![CC#Skin 的 Mods 来源、筛选与排行](docs/assets/mods.png)

## 功能

- **Mods 目录**：4 个社区来源、156 项随包目录条目，可手动刷新，也可添加自己的 GitHub 市场。
- **筛选与排行**：组合搜索、来源、分类和安装状态；按仓库 Stars、仓库最近更新、名称或本机浏览次数排序。
- **插件管理**：安装、启用、停用、更新与卸载，先选择、后应用，通过官方 Claude Code CLI 执行。
- **字体与排版**：分别设置中英文、界面与代码字体，调整字号、行距、段落间距和阅读宽度。
- **配色与主题**：浅色阅读底色、深色主题，以及样式组合保存和 JSON 导入导出。
- **备份与还原**：外观修改前创建完整备份，支持独立测试副本和应用还原。

目录条目可能来自同一仓库，Stars 与更新日期属于整个仓库。本机浏览只统计此 Mac 的详情打开次数，不上传记录。当前来源没有可核验的公开 Mod 下载量或全网浏览量，因此不提供这两种排行。来源与数据口径见 [Mods 使用说明](docs/MODS.md)。

## 安装

1. 下载上方安装包和发行页的 [`SHA256SUMS.txt`](https://github.com/Orxooo/ClaudeFont/releases/download/v1.2.0/SHA256SUMS.txt)。
2. 核对摘要，解压 ZIP，将 `CC#Skin.app` 放入「应用程序」。
3. 打开应用。使用字体和外观功能时，按「概览」完成 App 管理权限检测。

```sh
shasum -a 256 CCSkin-1.2.0-macOS-arm64.zip
```

客户端内置运行所需组件，无需 Python 或 Xcode。发行包使用 Apple 开发证书签名，未经 Apple 公证；首次打开说明见 [使用指南](docs/USAGE.md#安装与校验)。

从 claudefont、ClaudeFont 或 CcSkin 升级时，退出旧版后替换应用。原有 Bundle ID、设置、主题和备份目录保持兼容。

## 使用

**管理 Mods**：打开「Mods」，搜索和筛选目录，查看详情与源码，将所需操作加入待应用列表，再点击「应用所选更改」。也可以在「仓库」添加 GitHub 市场。浏览不会自动添加市场或安装插件；完成后，在目标 Code 会话运行 `/reload-plugins` 或重新打开会话，并确认实际效果。

**调整外观**：在「概览」选择目标，在「字体」「代码」「背景」调整，或从「主题」载入组合。彻底退出所选 Claude，再点击「应用设置」。重新打开 Claude 检查效果；撤销时退出 Claude，并在「更多操作」选择「还原应用」。

Mods 单独应用不修改或重新签名 Claude.app。外观修改沿用完整备份、补丁和签名流程；首次使用建议在独立测试副本确认。Mods 使用当前用户的 Claude Code 配置，不随外观页的正式／测试应用目标切换。

## 验证与兼容性

当前版本的检查、签名、界面及发行包验证范围见 [验证记录](docs/VERIFICATION.md)。第三方 Mods 在 Claude Desktop 中的实际效果取决于目标会话，尚未逐项验收。外观引擎的历史实际运行记录涵盖 Claude 2.19675.0；Claude 更新后应重新检查兼容性。

社区 Mods 会在本机执行代码。目录收录和仓库热度不代表每个第三方插件已经过安全审查。

## 数据与开发

设置和主题位于 `~/.config/claudefont/`，应用备份与日志位于 `~/.local/share/claudefont/`。更新检查、目录刷新和热度刷新访问 GitHub；本机详情浏览次数留在本机。

客户端采用 Swift / SwiftUI，内置 Swift 外观引擎。开发需要 Xcode 26+ 和有效的 Apple 签名身份。

[使用指南](docs/USAGE.md) · [Mods 说明](docs/MODS.md) · [构建与 CLI](docs/DEVELOPMENT.md) · [代码结构](docs/ARCHITECTURE.md) · [贡献指南](CONTRIBUTING.md)

## 许可

Copyright © 2026 Orxooo。项目采用 [GPL-3.0-only](LICENSE)，与 Anthropic 无隶属关系，不分发 Claude 应用代码或字体文件。社区元数据的 CC0／MIT 声明随包保留；第三方插件遵循各自许可证。详见 [NOTICE](NOTICE)。
