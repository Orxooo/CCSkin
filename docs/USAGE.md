# 使用指南 / User guide

[简体中文 README](../README.md) · [English README](../README.en.md) · [English guide](#english)

## 安装与校验

在[发行页](https://github.com/Orxooo/ClaudeFont/releases/latest)下载 macOS ZIP 与 `SHA256SUMS.txt`。将 ZIP 的 SHA-256 摘要与清单中的同名条目核对：

```sh
shasum -a 256 claudefont-1.0.0-macOS-arm64.zip
```

以上命令对应 V1.0.0；其他版本请使用发行页列出的文件名。解压后，将应用移入「应用程序」文件夹。

V1.0.0（构建 4）使用 Apple 开发证书签名，未经 Apple 公证。若 macOS 拦截首次打开，确认来源和摘要后，在「系统设置 → 隐私与安全性」选择「仍要打开」。

当前源码构建产物为 `ClaudeFont.app`，V1.0.0 发行包使用历史名称 `claudefont.app`。应用截图来自该发行版本，预览使用示例内容。

## 权限与应用

在「概览」选择目标并点击「检测权限」。如果访问被拒绝，按提示开启 macOS「App 管理」权限，再重新检测。

应用前确认字体已安装，并彻底退出所选 Claude；只关闭窗口不会退出应用。预览与载入主题不会自动写入，点击「应用设置」后才会生效。进度与结果可在「日志」中查看。

首次使用建议创建测试副本。测试副本使用独立配置，不复制正式 Claude 的登录或会话数据。

## 备份与还原

应用前会创建完整备份，失败时会尝试回滚。需要撤销修改时，退出 Claude，在「更多操作」中选择「还原应用」。还原需要匹配当前版本的完整原版备份；没有匹配备份时，请[重新安装官方 Claude](https://claude.ai/download)。

目标已有字体修改时，可在「概览」选择「接续已有修改」，提供同版本的完整原版 `.app` 备份，以及含 `config.json` 和可选 `themes.json` 的设置文件夹。核验通过后再应用。

## 字体、排版与主题

- 字号范围：80%–150%；正文行距：1.2–2.4 倍；段落间距：4–40 px；阅读宽度：480–1100 px。
- 英文可仅覆盖回复与标题，或同时覆盖界面、输入框和用户消息。
- 浅色背景与深色主题分别生效，不会主动切换 Claude 的外观模式。
- 终端保留自身字符网格与行距；代码连字取决于字体支持。
- 主题文件只包含样式设置，不包含字体文件；缺失字体会提示。

## 兼容性与更新

已记录的实际运行验证涵盖 Claude 2.19675.0 的启动与宋体显示。其他 Claude 版本、全部代码区域、Cowork / 虚拟机及账号网络功能尚未逐项验证；未知终端资源会拒绝适配。具体范围见[验证记录](VERIFICATION.md)。

Claude 更新后，先重新检查兼容性，再应用已保存的设置。ClaudeFont 更新需要手动下载替换；同版本的新构建不会触发版本更新提示。

## 本机数据与问题反馈

- 设置与主题：`~/.config/claudefont/`
- 完整备份、日志与事务记录：`~/.local/share/claudefont/`
- 测试应用与独立配置：`~/Library/Application Support/claudefont/`

应用改名保留原有 Bundle ID、CLI 命令与数据目录。正常替换应用会保留设置、主题与备份。

操作在本机执行，更新检查访问 GitHub Releases。工具不会上传聊天记录、登录信息或 API 密钥。

通过 [Issues](https://github.com/Orxooo/ClaudeFont/issues/new/choose) 提供系统、Claude、ClaudeFont 版本与构建号、目标类型、复现步骤和日志。提交前请移除用户名、私人路径、聊天内容与登录资料。

## English

### Installation and checksums

Download the macOS ZIP and `SHA256SUMS.txt` from [Releases](https://github.com/Orxooo/ClaudeFont/releases/latest). Compare the ZIP's SHA-256 digest with the entry for the same filename:

```sh
shasum -a 256 claudefont-1.0.0-macOS-arm64.zip
```

This command is for V1.0.0; use the filename listed on the release page for other versions. Extract the ZIP and move the app to Applications.

V1.0.0 (build 4) is signed with an Apple development certificate and is not notarized. If macOS blocks the first launch, verify the source and checksum, then choose **Open Anyway** in **System Settings → Privacy & Security**.

Current source builds produce `ClaudeFont.app`; the V1.0.0 package uses the historical `claudefont.app` name. App screenshots are from that release and previews use sample content.

### Access and applying changes

Select a target in **Overview** and choose **Check access**. If access is denied, follow the **App Management** instructions and check again.

Confirm the font is installed and quit the selected Claude completely; closing a window does not quit the app. Previews and loaded themes do not write changes automatically. Choose **Apply changes** to apply them, and check **Logs** for progress and results.

Start with a test copy on first use. It uses a separate profile without copying the main Claude's sign-in or conversation data.

### Backup and restoration

A complete backup is created before applying, with attempted rollback on failure. To undo changes, quit Claude and choose **Restore app** in **More actions**. Restoration requires a complete pristine backup matching the current version. Without one, [reinstall official Claude](https://claude.ai/download).

For existing font modifications, choose **Continue previous changes** in **Overview**. Provide a complete pristine `.app` backup of the same version and a settings folder with `config.json` and optional `themes.json`. Apply after validation succeeds.

### Fonts, layout and themes

- Font scaling: 80%–150%; body line height: 1.2–2.4×; paragraph spacing: 4–40 px; reading width: 480–1100 px.
- English changes can cover replies and headings, or also the interface, input and user messages.
- Light backgrounds and dark themes apply separately, without switching Claude's appearance mode.
- The terminal retains its own character grid and line height. Code ligatures depend on font support.
- Theme files contain style settings, without font files. Missing fonts are reported.

### Compatibility and updates

Recorded runtime verification covers startup and Songti rendering on Claude 2.19675.0. Other Claude versions, all code regions, Cowork / virtual machines and account/network features have not been individually verified. Unrecognized terminal resources reject adaptation. See the [verification record](VERIFICATION.md) for the scope.

Check compatibility after a Claude update before applying saved settings again. ClaudeFont updates install manually; same-version builds do not trigger a version notice.

### Local data and issue reports

- Settings and themes: `~/.config/claudefont/`
- Complete backups, logs and transactions: `~/.local/share/claudefont/`
- Test app and separate profile: `~/Library/Application Support/claudefont/`

The rename preserves the bundle ID, CLI command and data directories. A normal app replacement retains settings, themes and backups.

Operations run locally; update checks contact GitHub Releases. The tool does not upload conversations, login data or API keys.

Use [Issues](https://github.com/Orxooo/ClaudeFont/issues/new/choose) with system, Claude and ClaudeFont versions/build numbers, target type, reproduction steps and logs. Remove usernames, private paths, conversation content and login data before submitting.
