# ClaudeFont

Claude 桌面版的字体与外观定制工具，支持中英文字体、阅读排版、代码样式和主题管理。

[下载应用](https://github.com/Orxooo/ClaudeFont/releases/latest) · [English](README.en.md) · [更新记录](CHANGELOG.md) · [问题反馈](https://github.com/Orxooo/ClaudeFont/issues/new/choose)

适用于 macOS 26 及以上版本的 Apple Silicon Mac。

![字体与阅读排版设置](docs/assets/fonts.png)

## 功能

- **字体设置**：分别选择中文、英文与代码字体，调整字号和界面比例。
- **阅读排版**：调整正文行距、段落间距与阅读宽度。
- **代码样式**：为回复、代码块、Diff、编辑器和终端分别设置字体与字号。
- **外观配色**：分别设置浅色背景与深色主题。
- **主题管理**：保存样式组合，通过 JSON 文件导入与导出。
- **备份还原**：应用前创建完整备份，支持独立测试副本与应用还原。

## 安装

1. 从[发行页](https://github.com/Orxooo/ClaudeFont/releases/latest)下载 macOS 安装包。
2. 解压 ZIP，将应用移入「应用程序」文件夹。
3. 打开应用，按提示完成权限检测。

发行包内置运行所需组件，无需安装 Python 或 Xcode。下载校验与首次打开说明见[使用指南](docs/USAGE.md#安装与校验)。

## 使用

1. 在「概览」选择要调整的 Claude，首次使用建议创建测试副本。
2. 在「字体」「代码」「背景」中调整样式，或在「主题」中载入已保存的组合。
3. 彻底退出所选 Claude，再点击「应用设置」。
4. 重新打开 Claude，确认实际显示效果。

预览和载入主题不会自动写入 Claude。需要撤销修改时，退出 Claude，在「更多操作」中选择「还原应用」。

## 使用说明

ClaudeFont 会修改并重新签名所选 Claude 应用，应用前会创建完整备份。Claude 更新后应重新检查兼容性，再应用设置。

已记录的实际运行验证涵盖 Claude 2.19675.0 的启动与字体显示；其他版本和全部代码区域的兼容性仍需确认，详见[验证记录](docs/VERIFICATION.md)。

权限处理、还原、主题和数据位置见[使用指南](docs/USAGE.md)。问题反馈请附上系统与应用版本、复现步骤，以及移除私人信息的日志。

## 开发与贡献

客户端使用 Swift / SwiftUI，内置 Swift 引擎。开发需要 Xcode 26 或更高版本，以及有效的 Apple 签名身份。

[构建与 CLI](docs/DEVELOPMENT.md) · [代码结构](docs/ARCHITECTURE.md) · [贡献指南](CONTRIBUTING.md)

## 许可

本项目采用 [GPL-3.0-only](LICENSE) 许可，由 Orxooo 独立开发，与 Anthropic 无隶属关系。项目不分发 Claude 的应用代码或字体文件，详见[项目声明](NOTICE)。
