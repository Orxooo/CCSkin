## Mods 入口（CC#Skin 1.2.0）

「Mods」页提供多来源搜索、已安装插件、GitHub 市场和待应用列表。内置快照含 156 项：ClaudeMods 56 项、Awesome Mods 70 项、Hamza's Mods 25 项、T-AI-Labs 5 项。元数据分别来自 [omarcevi/claudemods](https://github.com/omarcevi/claudemods)（CC0）、[whyashthakker/awesome-claude-code-mods](https://github.com/whyashthakker/awesome-claude-code-mods)、[hamzafer/claude-code-mods](https://github.com/hamzafer/claude-code-mods) 和 [T-AI-Labs/claude-code-mods](https://github.com/T-AI-Labs/claude-code-mods)（后三者 MIT）。来源间可能收录相同功能或同名 Mod，安装身份包含市场名。许可证随包保留，不分发第三方插件代码。

来源、分类、安装状态和搜索可叠加。排序支持仓库 Stars、仓库最近推送、名称、本机浏览次数。「更新目录」分别刷新各来源，失败来源保留原目录；「更新热度」从 GitHub 获取仓库指标，按仓库去重，每小时缓存，每次最多更新 40 个仓库。随包已有 28 个仓库的日期快照，未知指标显示暂无数据并排在已知值之后。Stars 和更新日期属于整个仓库；没有公开可靠的 Mod 下载量和全网浏览量，不能用仓库 Stars 或 GitHub Release 下载量代替。「查看详情」只增加本机该条目的浏览次数，不上传记录。

「仓库」页提供四个来源入口、自定义市场，以及 [aidojo](https://mods.aidojo.si/) 和 [Claude Mods](https://claude-mods.com/) 外部大目录。浏览和筛选不注册市场；应用选中的安装时才添加对应来源，并重新读取实际市场来源，遇到同名市场指向其他仓库时停止。

需要已安装 [Claude Code 官方 CLI](https://code.claude.com/docs/en/setup) **2.1.287 或更新版本**。应用会查找 `~/.local/bin/claude`、Homebrew、`/usr/local/bin` 和 PATH；自定义安装可通过启动环境变量 `CLAUDEFONT_CLAUDE_CLI` 指定。Mods 作用于当前用户的 Claude Code 配置，供终端和 Desktop 本地 Code 会话共用，与字体页选择的正式／测试 Claude 应用目标无关。Desktop 内置 Claude Code 版本和每个 Mod 的显示兼容性须在目标会话确认。

- 在「发现」选择安装，或在「已安装」选择启用、停用、更新或卸载，再点击底部「应用所选更改」。同一插件只保留最后一次选择；执行前可取消。
- 「仓库」接受 `owner/repo` 或 GitHub HTTPS 仓库地址。点击「添加仓库」会立即通过官方 CLI 注册市场；点击「读取已添加市场的插件」可搜索其中的普通插件和 Mods。
- 此版本只修改用户级安装，其他作用域为只读。卸载使用官方 `--keep-data` 保留插件数据；更新先刷新对应市场，再更新插件。
- Mods 单独应用不修改或重签 Claude.app。勾选「同时应用样式」可随后执行现有字体备份、补丁和签名流程；修改正式 Claude 前沿用确认提示。
- 操作按顺序执行并读取安装状态。中途失败会停止，保留已完成项及剩余队列；这不是跨插件和应用包的整体回滚。完成后请在目标 Code 会话运行 `/reload-plugins` 或重新打开会话，再确认实际效果。

第三方 Mods 会在本机执行代码，安装前可从条目打开源码。首次打开本页只读取 CLI 状态，不会自动注册市场或安装插件。

Focused checks: `swiftc -parse-as-library gui/ModsCore.swift tests/check_mods.swift -o /tmp/CC#Skin-mods-check && /tmp/CC#Skin-mods-check`。隔离 CLI 检查还可传入 `MODS_TEST_CLI`、`MODS_TEST_CONFIG`；store 检查使用 `tests/check_mods_store.swift`，另需 `MODS_TEST_MARKET` 指向无 hooks 的本地测试市场。不要对日常配置运行测试变更。


## Mods entry (CC#Skin 1.2.0)

The Mods page aggregates 156 marketplace entries from four sources: [ClaudeMods](https://github.com/omarcevi/claudemods) (56, CC0), [Awesome Mods](https://github.com/whyashthakker/awesome-claude-code-mods) (70, MIT), [Hamza's Mods](https://github.com/hamzafer/claude-code-mods) (25, MIT) and [T-AI-Labs](https://github.com/T-AI-Labs/claude-code-mods) (5, MIT). Licenses accompany the metadata. Third-party plugin code is not bundled. Similar Mods can appear in multiple marketplaces; installation identities include the marketplace name.

Combine source, category, installation status and search. Sort by repository Stars, repository push date, name or local detail opens. Refresh catalog updates each source independently and preserves failed sources. Refresh metrics deduplicates repository requests, caches them for one hour and updates at most 40 repositories per request. The app bundles dated metrics for 28 repositories. Unknown metrics remain unavailable and sort after known values. Stars and push dates belong to the entire repository. Public per-Mod download/global-view counts are unavailable; neither Stars nor release-asset downloads are a substitute. Detail-view counts stay on this Mac and are never uploaded.

Repositories includes the four source cards, custom markets and links to larger external directories. Browsing never registers a market. Applying an explicit selected install may add its source, with a fresh identity check to reject conflicting marketplace names.

Install the [official Claude Code CLI](https://code.claude.com/docs/en/setup) **2.1.287 or later** first. CC#Skin checks `~/.local/bin/claude`, Homebrew, `/usr/local/bin` and PATH; `CLAUDEFONT_CLAUDE_CLI` can specify a custom executable at launch. Mods use the current user's Claude Code configuration shared by the terminal and local Desktop Code sessions. They do not follow the main/test app target selected for typography. Verify the Desktop's bundled Claude Code version and each mod's rendering in the target session.

- Queue install, enable, disable, update or uninstall, then choose Apply selected changes. The latest request replaces an earlier request for the same plugin; queued requests can be cancelled.
- Repositories accepts `owner/repo` or a GitHub HTTPS repository URL. Add repository registers the marketplace immediately through the official CLI. Read plugins lists searchable plugins and Mods from configured marketplaces.
- Only user-scope installations are editable. Other scopes are read-only. Uninstall uses `--keep-data`; updating first refreshes the corresponding marketplace.
- Mods alone never patch or re-sign Claude.app. Also apply styles runs the existing backup, typography patch and signing flow afterwards, retaining the main-app confirmation.
- Operations run sequentially with installed-state readback. A failure stops the queue and keeps completed changes and pending requests. This is not a transaction spanning plugins and the app bundle. Run `/reload-plugins` or reopen the target Code session and verify the result.

Community Mods run code on your machine; each discovery entry links to its source. Opening the page only reads state and does not add marketplaces or install plugins.

Focused checks: compile `gui/ModsCore.swift` with `tests/check_mods.swift` using `swiftc -parse-as-library`. Optional isolated CLI checks use `MODS_TEST_CLI` and `MODS_TEST_CONFIG`. Compile `gui/ModsCore.swift`, `gui/ModsStore.swift` and `tests/check_mods_store.swift` for store checks, also setting `MODS_TEST_MARKET` to a harmless local fixture marketplace. Never run test mutations against everyday configuration.

