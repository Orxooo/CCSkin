// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct ModsView: View {
    @ObservedObject var store: ModsStore
    let zh: Bool
    let locked: Bool
    @State private var section = 0
    @State private var search = ""
    @State private var repository = ""
    @State private var showLog = false
    @State private var query = ModsQuery()
    @State private var visibleLimit = 40
    @State private var detail: ModListing?
    @Environment(\.colorScheme) private var scheme
    private let accent = Color(hex:0xA75E46)
    private func l(_ cn: String, _ en: String) -> String { zh ? cn : en }

    var body: some View {
        VStack(alignment:.leading, spacing:20) {
            statusCard
            HStack(spacing:8) {
                ForEach(0..<3) { index in
                    Button { section = index } label: {
                        Text([l("发现", "Discover"),l("已安装", "Installed"),l("仓库", "Repositories")][index])
                            .foregroundStyle(section == index ? accent : .primary)
                    }
                    .buttonStyle(WorkspaceActionStyle())
                }
                Spacer()
                if store.busy || store.catalogBusy || store.statisticsBusy { ProgressView().controlSize(.small) }
            }
            TextField(l("搜索名称、作者或功能", "Search names, authors or features"), text:$search)
                .textFieldStyle(.plain).padding(14)
                .background(Color.primary.opacity(0.045), in:RoundedRectangle(cornerRadius:12))
                .accessibilityLabel(l("搜索 Mods", "Search Mods"))
            if !store.error.isEmpty {
                VStack(alignment:.leading, spacing:6) {
                    Label(l("操作未完成", "Operation incomplete"), systemImage:"exclamationmark.triangle")
                        .font(.system(size:14, weight:.semibold)).foregroundStyle(.red)
                    Text(store.error).font(.system(size:12)).textSelection(.enabled)
                }.frame(maxWidth:.infinity, alignment:.leading).padding(18)
                    .background(Color.red.opacity(0.06), in:RoundedRectangle(cornerRadius:16))
            }
            if section == 0 { discovery }
            else if section == 1 { installed }
            else { repositories }
            if !store.queue.isEmpty { pending }
            if !store.log.isEmpty {
                DisclosureGroup(l("操作记录", "Operation log"), isExpanded:$showLog) {
                    Text(store.log).font(.system(size:11, design:.monospaced)).textSelection(.enabled)
                        .frame(maxWidth:.infinity, alignment:.leading).padding(.top,10)
                }
            }
        }
        .task { await store.start() }
        .onChange(of:search) { _,_ in visibleLimit = 40 }
        .onChange(of:query) { _,_ in visibleLimit = 40 }
        .sheet(item:$detail) { entry in detailView(entry) }
    }

    private var statusCard: some View {
        VStack(alignment:.leading, spacing:12) {
            HStack(alignment:.top) {
                Image(systemName:"puzzlepiece.extension").font(.system(size:26)).foregroundStyle(accent)
                VStack(alignment:.leading, spacing:5) {
                    Text(l("你的 Claude 扩展入口", "Your Claude extensions"))
                        .font(.system(size:18, weight:.semibold))
                    Text(store.cliURL == nil ? l("未找到 Claude Code CLI", "Claude Code CLI not found") : store.version)
                        .font(.system(size:12)).foregroundStyle(.secondary)
                }
                Spacer()
                Button { Task { await store.refresh() } } label: {
                    Label(l("刷新状态", "Refresh status"), systemImage:"arrow.clockwise")
                }.disabled(store.busy || locked)
            }
            Text(l("Mods 应用到当前用户的 Claude Code，供终端与 Desktop 本地 Code 会话使用。这里的设置不随上方 Claude 应用目标切换。",
                   "Mods use the current user's Claude Code settings, shared by the terminal and local Desktop Code sessions. They do not follow the selected Claude app target."))
                .font(.system(size:12)).foregroundStyle(.secondary).fixedSize(horizontal:false, vertical:true)
            if store.cliURL == nil {
                Link(l("安装官方 Claude Code CLI", "Install the official Claude Code CLI"), destination:URL(string:"https://code.claude.com/docs/en/setup")!)
            }
            if store.needsReload {
                Label(l("配置已改变；请在目标 Code 会话运行 /reload-plugins，或重新打开会话后确认效果。", "Settings changed. Run /reload-plugins in the target Code session, or reopen it, then verify the result."), systemImage:"arrow.triangle.2.circlepath")
                    .font(.system(size:12)).foregroundStyle(accent).textSelection(.enabled)
            }
            Text(l("社区扩展会在本机执行代码；安装前可打开源码查看。", "Community extensions run code on your Mac. Open the source before installing."))
                .font(.system(size:11)).foregroundStyle(.secondary)
        }.padding(22).frame(maxWidth:.infinity, alignment:.leading)
            .background(cardColor, in:RoundedRectangle(cornerRadius:22))
    }

    private var discovery: some View {
        VStack(alignment:.leading, spacing:14) {
            HStack {
                VStack(alignment:.leading, spacing:3) {
                    Text(l("探索 Mods", "Explore Mods")).font(.system(size:18, weight:.semibold))
                    Text("\(ModsCatalog.sources.count) " + l("个来源", "sources") + " · \(store.catalog.count) Mods")
                        .font(.system(size:11)).foregroundStyle(.secondary)
                }
                Spacer()
                Button { Task { await store.refreshCatalog() } } label: {
                    Label(l("更新目录", "Refresh catalog"), systemImage:"arrow.down.circle")
                }.disabled(store.catalogBusy || locked)
                Button { Task { await store.refreshStatistics() } } label: {
                    Label(l("更新热度", "Refresh metrics"), systemImage:"chart.line.uptrend.xyaxis")
                }.disabled(store.statisticsBusy || locked)
            }
            discoveryFilters
            Text(l("热度按 GitHub 仓库 Stars 排序，同一仓库的 Mods 共用该指标。下载量与全网浏览量暂无公开数据；本机浏览仅记录此 Mac 打开详情的次数。", "Popularity uses GitHub repository Stars, shared by Mods in the same repository. Public downloads and global views are unavailable; local views count detail opens on this Mac only."))
                .font(.system(size:11)).foregroundStyle(.secondary)
            if let date = store.statistics.values.map(\.fetchedAt).max() {
                Text(l("仓库数据快照：", "Repository data snapshot: ") + date.formatted(date:.abbreviated,time:.shortened))
                    .font(.system(size:10)).foregroundStyle(.secondary)
            }
            if !store.catalogNote.isEmpty { Text(store.catalogNote).font(.system(size:11)).foregroundStyle(.secondary) }
            if !store.statisticsNote.isEmpty { Text(store.statisticsNote).font(.system(size:11)).foregroundStyle(.secondary) }
            let entries = filteredEntries
            HStack {
                Text("\(entries.count) " + l("项结果", "results")).font(.system(size:12,weight:.medium))
                Spacer()
                Button(l("重置筛选", "Reset filters")) { query = ModsQuery(); search = "" }
                    .font(.system(size:11))
            }
            if entries.isEmpty { empty(l("没有匹配的 Mods", "No matching Mods")) }
            ForEach(Array(entries.prefix(visibleLimit))) { entry in
                row(title:entry.name, detail:entry.description, footnote:sourceName(entry.sourceID) + " · " + categoryName(entry.categoryKey) + "\n" + metrics(entry) + "\n" + entry.author + " · " + entry.pluginID) {
                    Button(l("查看详情", "Details")) { store.recordView(entry); detail = entry }
                    if let url = entry.sourceURL { Link(l("源码", "Source"),destination:url) }
                    if store.installed.contains(where: { $0.pluginID == entry.pluginID && $0.isUser }) {
                        Text(l("已安装", "Installed")).font(.system(size:12)).foregroundStyle(.secondary)
                    } else { queueButton(.install, entry.pluginID) }
                }
            }
            if entries.count > visibleLimit {
                Button(l("再显示 40 项", "Show 40 more")) { visibleLimit += 40 }
                    .frame(maxWidth:.infinity)
            }
        }
    }

    private var filteredEntries: [ModListing] {
        var value = query; value.search = search
        return value.apply(store.catalog,installedIDs:Set(store.installed.filter(\.isUser).map(\.pluginID)),statistics:store.statistics,views:store.views)
    }

    private var discoveryFilters: some View {
        LazyVGrid(columns:[GridItem(.flexible(),spacing:24),GridItem(.flexible())],alignment:.leading,spacing:14) {
            filterField(l("来源", "Source"),selection:$query.source,options:
                [.init(id:"",title:l("全部来源", "All sources"))] + ModsCatalog.sources.map { .init(id:$0.id,title:$0.name) })
            filterField(l("分类", "Category"),selection:$query.category,options:
                [.init(id:"",title:l("全部分类", "All categories"))] + Array(Set(store.catalog.map(\.categoryKey))).sorted().map { .init(id:$0,title:categoryName($0)) })
            filterField(l("安装状态", "Installation"),selection:Binding(get:{ query.state.rawValue },set:{ query.state = ModsQuery.State(rawValue:$0) ?? .all }),options:[
                .init(id:"all",title:l("全部", "All")),.init(id:"installed",title:l("已安装", "Installed")),.init(id:"notInstalled",title:l("未安装", "Not installed"))])
            filterField(l("排序", "Sort"),selection:Binding(get:{ query.sort.rawValue },set:{ query.sort = ModsQuery.Sort(rawValue:$0) ?? .stars }),options:[
                .init(id:"stars",title:l("热度 · 仓库 Stars", "Repository Stars")),.init(id:"updated",title:l("最近更新 · 仓库", "Recently pushed")),
                .init(id:"name",title:l("名称 A–Z", "Name A–Z")),.init(id:"localViews",title:l("本机浏览次数", "Local views"))])
        }.frame(maxWidth:.infinity,alignment:.leading).padding(20)
            .background(cardColor,in:RoundedRectangle(cornerRadius:16))
    }

    private func filterField(_ label: String, selection: Binding<String>, options: [ModsFilterControl.Option]) -> some View {
        HStack(spacing:12) {
            Text(label).font(.system(size:12,weight:.medium)).foregroundStyle(.secondary)
                .frame(width:zh ? 60 : 78,alignment:.leading)
            ModsFilterControl(label:label,options:options,selection:selection)
                .frame(maxWidth:.infinity).frame(height:38)
        }.frame(maxWidth:.infinity,alignment:.leading)
    }

    private func sourceName(_ id: String) -> String { ModsCatalog.sources.first { $0.id == id }?.name ?? id }
    private func categoryName(_ value: String) -> String {
        guard zh else { return value }
        return ["session":"会话监测","git":"Git 工具","files":"文件工具","text":"文本工具","workflow":"工作流","desktop":"Desktop 扩展","ui":"界面","productivity":"效率","safety":"安全","security":"安全防护","games":"游戏","game":"游戏","other":"其他","tools":"工具","See what's happening":"状态监测","Guard your repo":"仓库保护","While you wait":"等待时刻" ][value] ?? value
    }
    private func metrics(_ entry: ModListing) -> String {
        let stats = entry.repository.flatMap { store.statistics[$0.lowercased()] }
        var text = stats.map { "★ \($0.stars) " + l("仓库 Stars", "repository Stars") } ?? l("仓库 Stars 暂无数据", "Repository Stars unavailable")
        if let date = stats?.pushedAt { text += " · " + l("仓库更新 ", "Pushed ") + date.formatted(date:.numeric,time:.omitted) }
        return text + " · " + l("本机浏览 ", "Local views ") + "\(store.views[entry.id,default:0])"
    }
    private func detailView(_ entry: ModListing) -> some View {
        VStack(alignment:.leading,spacing:16) {
            HStack {
                Text(entry.name).font(.system(size:24,weight:.semibold))
                Spacer()
                Button(l("关闭", "Close")) { detail = nil }.keyboardShortcut(.cancelAction)
            }
            Text(entry.description).font(.system(size:14)).fixedSize(horizontal:false,vertical:true)
            Text(sourceName(entry.sourceID) + " · " + categoryName(entry.categoryKey)).foregroundStyle(accent)
            Text(metrics(entry)).font(.system(size:12)).foregroundStyle(.secondary)
            Text(entry.pluginID).font(.system(size:12,design:.monospaced)).textSelection(.enabled)
            Text(entry.repository ?? entry.url).font(.system(size:12)).textSelection(.enabled)
            if !entry.tags.isEmpty { Text(entry.tags.joined(separator:" · ")).font(.system(size:12)).foregroundStyle(.secondary) }
            Text(l("热度和更新日期属于整个仓库，并不代表该 Mod 的下载量或验证结果。本机浏览次数只保存在本机。", "Stars and push dates belong to the hosting repository; they do not measure this Mod's downloads or validation. Local detail counts stay on this Mac."))
                .font(.system(size:11)).foregroundStyle(.secondary)
            HStack {
                if let url = entry.sourceURL { Link(l("打开源码与说明 ↗", "Open source and instructions ↗"),destination:url) }
                Spacer()
                if store.installed.contains(where: { $0.pluginID == entry.id && $0.isUser }) {
                    Text(l("已安装", "Installed")).foregroundStyle(.secondary)
                } else { queueButton(.install,entry.id) }
            }
        }.padding(28).frame(width:600)
    }

    private var installed: some View {
        VStack(alignment:.leading, spacing:12) {
            Text(l("已安装插件与 Mods", "Installed plugins and Mods")).font(.system(size:18, weight:.semibold))
            Text(l("官方列表也包含普通插件。此处仅修改用户级安装；其他作用域保留为只读。卸载会保留插件数据。", "The official list also includes regular plugins. Only user-scope installations are editable here; other scopes are read-only. Uninstall keeps plugin data."))
                .font(.system(size:12)).foregroundStyle(.secondary)
            let entries = store.installed.filter { matches([$0.pluginID]) }
            if entries.isEmpty { empty(store.stateKnown ? l("暂无匹配的已安装插件", "No matching installed plugins") : l("尚未读取安装状态", "Installed state has not been read")) }
            ForEach(entries) { entry in
                row(title:entry.pluginID, detail:"v\(entry.version) · \(entry.scope) · " + (entry.enabled ? l("已启用", "Enabled") : l("已停用", "Disabled")), footnote:"") {
                    if entry.isUser && ModOperation.supportsLifecycle(entry.pluginID) {
                        queueButton(entry.enabled ? .disable : .enable, entry.pluginID)
                        queueButton(.update, entry.pluginID)
                        queueButton(.uninstall, entry.pluginID)
                    } else { Text(l("只读", "Read-only")).foregroundStyle(.secondary) }
                }
            }
        }
    }

    private var repositories: some View {
        VStack(alignment:.leading, spacing:16) {
            Text(l("内置仓库来源", "Built-in sources")).font(.system(size:18,weight:.semibold))
            Text(l("目录可直接浏览；只有点击添加市场或应用已选安装时才注册仓库。", "Browse without registering. A marketplace is added only when you add it here or apply a selected install."))
                .font(.system(size:12)).foregroundStyle(.secondary)
            ForEach(ModsCatalog.sources.filter { matches([$0.name,$0.repository]) }) { source in
                row(title:source.name,detail:source.repository,footnote:source.license + " · \(store.catalog.filter { $0.sourceID == source.id }.count) Mods" + (store.sourceFailures[source.id].map { "\n" + $0 } ?? "")) {
                    Link(l("仓库 ↗", "Repository ↗"),destination:URL(string:"https://github.com/"+source.repository)!)
                    Button(l("浏览", "Browse")) { query = ModsQuery(); query.source = source.id; search = ""; section = 0 }
                    if (try? ModsCatalog.repositoryToAdd(for:source,registered:store.marketplaces)) == nil,
                       store.marketplaces.contains(where: { $0.name == source.marketplace && $0.repo?.lowercased() == source.repository.lowercased() }) {
                        Text(l("已添加", "Added")).foregroundStyle(.secondary)
                    } else {
                        Button(l("添加市场", "Add marketplace")) { Task { await store.addRepository(source.repository) } }
                            .disabled(!store.canMutate || locked)
                    }
                }
            }
            HStack {
                Link(l("aidojo 大目录 ↗", "aidojo directory ↗"),destination:URL(string:"https://mods.aidojo.si/")!)
                Link(l("Claude Mods 目录 ↗", "Claude Mods directory ↗"),destination:URL(string:"https://claude-mods.com/")!)
            }.font(.system(size:12))
            VStack(alignment:.leading, spacing:12) {
                Text(l("添加 GitHub 市场", "Add a GitHub marketplace")).font(.system(size:18, weight:.semibold))
                HStack {
                    TextField("owner/repo", text:$repository).textFieldStyle(.roundedBorder)
                        .accessibilityLabel(l("GitHub 仓库", "GitHub repository"))
                    Button(l("添加仓库", "Add repository")) {
                        let value = repository
                        Task { await store.addRepository(value); if store.error.isEmpty { repository = "" } }
                    }.disabled(repository.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || !store.canMutate || locked)
                }
                Text(l("添加会立即调用官方 CLI 注册市场；不会自动安装其中插件。", "Adding registers the marketplace immediately through the official CLI. Its plugins are not installed automatically."))
                    .font(.system(size:11)).foregroundStyle(.secondary)
            }.padding(20).background(cardColor, in:RoundedRectangle(cornerRadius:20))
            ForEach(store.marketplaces.filter { matches([$0.name,$0.repo ?? ""]) }) { market in
                row(title:market.name, detail:market.repo ?? market.source ?? "", footnote:"") { EmptyView() }
            }
            Button { Task { await store.loadAvailable() } } label: {
                Label(l("读取已添加市场的插件", "Read plugins from added marketplaces"), systemImage:"list.bullet.rectangle")
            }.disabled(store.busy || locked || store.cliURL == nil)
            let entries = store.available.filter { matches([$0.name,$0.description ?? "",$0.marketplaceName]) }
            ForEach(Array(entries.prefix(50))) { entry in
                row(title:entry.name, detail:entry.description ?? "", footnote:entry.marketplaceName) {
                    if store.installed.contains(where: { $0.pluginID == entry.id && $0.isUser }) {
                        Text(l("已安装", "Installed")).foregroundStyle(.secondary)
                    } else { queueButton(.install, entry.id) }
                }
            }
            if entries.count > 50 {
                Text(l("显示前 50 项，请搜索缩小范围。", "Showing the first 50 results. Search to narrow the list."))
                    .font(.system(size:12)).foregroundStyle(.secondary)
            }
        }
    }

    private var pending: some View {
        VStack(alignment:.leading, spacing:12) {
            Text(l("待应用", "Pending changes")).font(.system(size:18, weight:.semibold))
            ForEach(store.queue) { operation in
                HStack {
                    Text(operation.pluginID).font(.system(size:12, design:.monospaced)).lineLimit(1)
                    Spacer()
                    Text(title(operation.kind)).font(.system(size:12)).foregroundStyle(accent)
                    Button(l("取消", "Cancel")) { store.queue.removeAll { $0.id == operation.id } }
                        .disabled(store.busy || locked)
                }
            }
            Text(l("点击底部“应用所选更改”执行。失败时停在当前项，已完成的项目会保留。", "Choose Apply selected changes below. A failure stops the queue; completed operations are kept."))
                .font(.system(size:11)).foregroundStyle(.secondary)
        }.padding(20).background(accent.opacity(0.06), in:RoundedRectangle(cornerRadius:20))
    }

    private func title(_ kind: ModOperation.Kind) -> String {
        switch kind {
        case .install: return l("安装", "Install")
        case .enable: return l("启用", "Enable")
        case .disable: return l("停用", "Disable")
        case .update: return l("更新", "Update")
        case .uninstall: return l("卸载", "Uninstall")
        }
    }
    private func queueButton(_ kind: ModOperation.Kind, _ id: String) -> some View {
        Button { store.enqueue(kind,id) } label: {
            Text(store.queue.contains(ModOperation(kind:kind,pluginID:id)) ? l("已选", "Selected") : title(kind))
        }.disabled(!store.canMutate || locked)
    }
    private func matches(_ values: [String]) -> Bool {
        search.isEmpty || values.contains { $0.localizedCaseInsensitiveContains(search) }
    }
    private var cardColor: Color { Color(hex:scheme == .dark ? 0x2D2D2D : 0xFFFEFC) }
    private func empty(_ text: String) -> some View {
        Text(text).font(.system(size:14)).foregroundStyle(.secondary)
            .frame(maxWidth:.infinity, minHeight:85)
    }
    private func row<Actions: View>(title: String, detail: String, footnote: String, @ViewBuilder actions: () -> Actions) -> some View {
        VStack(alignment:.leading, spacing:12) {
            HStack(alignment:.top, spacing:12) {
                Image(systemName:"puzzlepiece.extension").foregroundStyle(accent).padding(10)
                    .background(accent.opacity(0.08), in:RoundedRectangle(cornerRadius:12))
                VStack(alignment:.leading, spacing:6) {
                    Text(title).font(.system(size:15, weight:.semibold)).textSelection(.enabled)
                    if !detail.isEmpty { Text(detail).font(.system(size:12)).foregroundStyle(.secondary).fixedSize(horizontal:false, vertical:true) }
                    if !footnote.isEmpty { Text(footnote).font(.system(size:10)).foregroundStyle(.secondary).textSelection(.enabled) }
                }
            }
            HStack { Spacer(); actions() }.font(.system(size:12))
        }.padding(18).frame(maxWidth:.infinity, alignment:.leading)
            .background(cardColor, in:RoundedRectangle(cornerRadius:20))
            .overlay(RoundedRectangle(cornerRadius:20).strokeBorder(Color.primary.opacity(0.06)))
    }
}
