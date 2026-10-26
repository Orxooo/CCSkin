// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import Combine

@MainActor final class ModsStore: ObservableObject {
    @Published var catalog: [ModListing] = []
    @Published var installed: [InstalledMod] = []
    @Published var marketplaces: [ModMarketplace] = []
    @Published var available: [AvailableMod] = []
    @Published var queue: [ModOperation] = []
    @Published var busy = false
    @Published var catalogBusy = false
    @Published var statisticsBusy = false
    @Published var statistics: [String:ModRepositoryStats] = [:]
    @Published var views: [String:Int] = [:]
    @Published var sourceFailures: [String:String] = [:]
    @Published var catalogNote = ""
    @Published var statisticsNote = ""
    @Published var stateKnown = false
    @Published var error = ""
    @Published var log = ""
    @Published var needsReload = false
    @Published var catalogRefreshed = false
    @Published var version = ""
    @Published var cliURL: URL?
    private var started = false
    private let selectedExecutable: URL?
    private let commandEnvironment: [String:String]
    private let commandTimeout: TimeInterval
    private let storageDirectory: URL
    private let fetchData: @Sendable (URL) async throws -> Data

    init(executable: URL? = nil, environment: [String:String] = [:], commandTimeout: TimeInterval = 120,
         storageDirectory: URL? = nil, fetch: (@Sendable (URL) async throws -> Data)? = nil) {
        selectedExecutable = executable; commandEnvironment = environment; self.commandTimeout = commandTimeout
        let config = ProcessInfo.processInfo.environment["CLAUDEFONT_CONFIG"] ?? NSHomeDirectory()+"/.config/claudefont/config.json"
        self.storageDirectory = storageDirectory ?? URL(fileURLWithPath:config).deletingLastPathComponent()
        fetchData = fetch ?? { url in try await Self.fetchRemote(url) }
        cliURL = executable ?? ModsCLI.discover()
        let bundled = Bundle.main.url(forResource:"mods-catalog", withExtension:"json")
        for url in [bundled, self.storageDirectory.appendingPathComponent("mods-catalog.json"), cacheURL].compactMap({ $0 }) {
            if let data = try? Data(contentsOf:url), let values = try? JSONDecoder().decode([ModListing].self, from:data), !values.isEmpty {
                catalog = ModsCatalog.merge(bundled:catalog,cached:values)
            }
        }
        for url in [Bundle.main.url(forResource:"mods-statistics",withExtension:"json"), statisticsURL].compactMap({ $0 }) {
            if let data = try? Data(contentsOf:url), let values = try? JSONDecoder().decode([String:ModRepositoryStats].self,from:data) {
                statistics.merge(values) { old,new in old.fetchedAt > new.fetchedAt ? old : new }
            }
        }
        if let data = try? Data(contentsOf:viewsURL), let values = try? JSONDecoder().decode([String:Int].self,from:data) {
            views = values.filter { $0.value >= 0 }
        }
    }

    private var cacheURL: URL { storageDirectory.appendingPathComponent("mods-catalog-v2.json") }
    private var statisticsURL: URL { storageDirectory.appendingPathComponent("mods-statistics.json") }
    private var viewsURL: URL { storageDirectory.appendingPathComponent("mods-browsing.json") }
    private func save<Value: Encodable>(_ value: Value, to url: URL) throws {
        try FileManager.default.createDirectory(at:storageDirectory,withIntermediateDirectories:true)
        try JSONEncoder().encode(value).write(to:url,options:.atomic)
    }
    func recordView(_ entry: ModListing) {
        let count = views[entry.id,default:0]
        views[entry.id] = count < Int.max ? count + 1 : count
        do { try save(views,to:viewsURL) } catch { self.error = error.localizedDescription }
    }
    private var runner: ModsCLI? { cliURL.map { ModsCLI(executable:$0, environment:commandEnvironment, timeout:commandTimeout) } }
    var canMutate: Bool { cliURL != nil && ModsCLI.supportsMods(version) && stateKnown && !busy }

    func start() async {
        guard !started else { return }; started = true
        await refresh()
    }

    private func command(_ args: [String]) async throws -> ModsCommandResult {
        guard let runner else { throw ModsError.invalid("Claude Code CLI is not installed. Install the official CLI, then refresh.") }
        return try await runner.run(args)
    }

    private func snapshot() async throws {
        let plugins = try await command(["plugin","list","--json"])
        guard plugins.code == 0 else { throw ModsError.invalid(plugins.output) }
        let decoded = try ModsSnapshot.decodePlugins(Data(plugins.output.utf8))
        let repos = try await command(["plugin","marketplace","list","--json"])
        guard repos.code == 0 else { throw ModsError.invalid(repos.output) }
        let decodedRepos = try JSONDecoder().decode([ModMarketplace].self, from:Data(repos.output.utf8))
        installed = decoded; marketplaces = decodedRepos; stateKnown = true
    }

    func refresh() async {
        guard !busy else { return }
        busy = true; error = ""; defer { busy = false }
        cliURL = selectedExecutable ?? ModsCLI.discover()
        do {
            let result = try await command(["--version"])
            guard result.code == 0 else { throw ModsError.invalid(result.output) }
            version = result.output.trimmingCharacters(in:.whitespacesAndNewlines)
            guard ModsCLI.supportsMods(version) else {
                throw ModsError.invalid("Update Claude Code CLI to 2.1.287 or later, then refresh. / 请升级 Claude Code CLI 后刷新。")
            }
            try await snapshot()
        } catch { stateKnown = false; self.error = error.localizedDescription }
    }

    func refreshCatalog() async {
        guard !catalogBusy else { return }
        catalogBusy = true; defer { catalogBusy = false }
        let loader = fetchData
        var successes = 0
        await withTaskGroup(of:(String,[ModListing]?,String?).self) { group in
            for source in ModsCatalog.sources {
                group.addTask {
                    do {
                        let entries: [ModListing]
                        if source.id == ModsCatalog.repository {
                            async let directory = loader(ModsCatalog.directoryURL)
                            async let manifest = loader(source.manifestURL)
                            entries = try await ModsCatalog.decode(directory:directory,marketplace:manifest)
                        } else { entries = try ModsCatalog.decodeManifest(await loader(source.manifestURL),source:source) }
                        return (source.id,entries,nil)
                    } catch { return (source.id,nil,error.localizedDescription) }
                }
            }
            for await (source,entries,failure) in group {
                if let entries {
                    catalog = ModsCatalog.merge(bundled:catalog,cached:entries)
                    sourceFailures.removeValue(forKey:source); successes += 1
                } else { sourceFailures[source] = failure }
            }
        }
        catalogRefreshed = successes > 0
        catalogNote = "\(successes)/\(ModsCatalog.sources.count) sources refreshed · 失败来源保留原目录 / Failed sources keep their saved entries."
        do {
            if successes > 0 { try save(catalog,to:cacheURL) }
        } catch { self.error = error.localizedDescription }
    }

    func refreshStatistics() async {
        guard !statisticsBusy else { return }
        statisticsBusy = true; defer { statisticsBusy = false }
        let repos = Array(Set(catalog.compactMap { $0.repository?.lowercased() })).sorted()
        let stale = repos.filter { Date().timeIntervalSince(statistics[$0]?.fetchedAt ?? .distantPast) >= 3600 }
        let pending = Array(stale.prefix(40)); let loader = fetchData
        var successes = 0; var failures = 0
        for offset in stride(from:0,to:pending.count,by:4) {
            await withTaskGroup(of:(String,ModRepositoryStats?).self) { group in
                for repo in pending[offset..<min(offset+4,pending.count)] {
                    group.addTask {
                        do {
                            let data = try await loader(URL(string:"https://api.github.com/repos/"+repo)!)
                            return (repo,try ModRepositoryStats.decode(data))
                        } catch { return (repo,nil) }
                    }
                }
                for await (repo,value) in group {
                    if let value { statistics[repo] = value; successes += 1 } else { failures += 1 }
                }
            }
            statisticsNote = "\(min(offset+4,pending.count))/\(pending.count)"
        }
        statisticsNote = "\(repos.count-stale.count) cached · \(successes) refreshed · \(failures) unavailable. " +
            "仓库指标每小时缓存；失败保留旧值 / Repository metrics cached for 1 hour; failures keep prior values."
        if stale.count > 40 { statisticsNote += " 40 repositories per refresh." }
        do { if successes > 0 { try save(statistics,to:statisticsURL) } }
        catch { self.error = error.localizedDescription }
    }

    nonisolated private static func fetchRemote(_ url: URL) async throws -> Data {
        var req = URLRequest(url:url); req.timeoutInterval = 20
        req.setValue("CCSkin",forHTTPHeaderField:"User-Agent")
        if url.host == "api.github.com" { req.setValue("application/vnd.github+json",forHTTPHeaderField:"Accept") }
        let (data, response) = try await URLSession.shared.data(for:req)
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 2_000_000 else {
            throw ModsError.invalid("Could not refresh the community catalog. The saved catalog is still available.")
        }
        return data
    }

    func enqueue(_ kind: ModOperation.Kind, _ pluginID: String) {
        guard canMutate else { return }
        do {
            _ = try ModOperation(kind:kind, pluginID:pluginID).arguments()
            // One final requested action per plugin. This avoids contradictory commands.
            queue.removeAll { $0.pluginID == pluginID }
            queue.append(ModOperation(kind:kind, pluginID:pluginID))
        } catch { self.error = error.localizedDescription }
    }

    func addRepository(_ source: String) async {
        guard canMutate else { return }
        busy = true; error = ""; defer { busy = false }
        do {
            let repo = try ModsRepository.parse(source)
            if let known = ModsCatalog.sources.first(where: { $0.repository.lowercased() == repo.lowercased() }) {
                if try ModsCatalog.repositoryToAdd(for:known,registered:marketplaces) == nil { return }
            }
            let result = try await command(["plugin","marketplace","add",repo,"--scope","user","--json"])
            log += "\nmarketplace add \(repo)\n" + result.output
            guard result.code == 0 else { throw ModsError.invalid(result.output) }
            needsReload = true
            try await snapshot()
            try await loadAvailableSnapshot()
        } catch {
            let detail = error.localizedDescription
            do { try await snapshot() } catch { stateKnown = false }
            self.error = detail
        }
    }

    private func loadAvailableSnapshot() async throws {
        let result = try await command(["plugin","list","--json","--available"])
        guard result.code == 0 else { throw ModsError.invalid(result.output) }
        available = try ModsSnapshot.decodeAvailable(Data(result.output.utf8))
    }

    func loadAvailable() async {
        guard !busy else { return }; busy = true; error = ""; defer { busy = false }
        do { try await loadAvailableSnapshot() }
        catch { self.error = error.localizedDescription }
    }

    private func verify(_ operation: ModOperation) -> Bool {
        let item = installed.first { $0.pluginID == operation.pluginID && $0.isUser }
        switch operation.kind {
        case .uninstall: return item == nil
        case .disable: return item?.enabled == false
        case .enable: return item?.enabled == true
        case .install, .update: return item != nil
        }
    }

    /// Stop at the first failure; completed operations are removed after readback.
    /// This is deliberately not an all-or-nothing transaction across plugins/apps.
    func apply() async -> Bool {
        guard canMutate else { return false }
        guard !queue.isEmpty else { return true }
        busy = true; error = ""; defer { busy = false }
        do {
            while let operation = queue.first {
                if operation.kind == .install, let entry = catalog.first(where: { $0.id == operation.pluginID }),
                   let source = ModsCatalog.sources.first(where: { $0.id == entry.sourceID }) {
                    // Another Claude session may have changed the registry since this page loaded.
                    try await snapshot()
                    if let repo = try ModsCatalog.repositoryToAdd(for:source,registered:marketplaces) {
                        let added = try await command(["plugin","marketplace","add",repo,"--scope","user","--json"])
                        log += "\nAdd marketplace \(repo)\n" + added.output
                        guard added.code == 0 else { throw ModsError.invalid(added.output) }
                        needsReload = true
                        try await snapshot()
                        guard try ModsCatalog.repositoryToAdd(for:source,registered:marketplaces) == nil else {
                            throw ModsError.invalid("Marketplace registration was not confirmed. Refresh before retrying.")
                        }
                    }
                }
                if let args = try operation.refreshArguments() {
                    let result = try await command(args)
                    log += "\nRefresh marketplace\n" + result.output
                    guard result.code == 0 else { throw ModsError.invalid(result.output) }
                }
                let result = try await command(operation.arguments())
                log += "\n\(operation.kind.rawValue) \(operation.pluginID)\n" + result.output
                if result.code == 0 { needsReload = true }
                do { try await snapshot() }
                catch { stateKnown = false; throw error }
                guard result.code == 0 else { throw ModsError.invalid(result.output) }
                guard verify(operation) else { throw ModsError.invalid("The installed state did not confirm the operation. Refresh before retrying.") }
                queue.removeFirst()
            }
            return true
        } catch {
            let detail = error.localizedDescription
            do { try await snapshot() } catch { stateKnown = false }
            self.error = detail; return false
        }
    }
}
