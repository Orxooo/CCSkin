// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import Darwin

enum ModsError: LocalizedError {
    case invalid(String), timeout
    var errorDescription: String? {
        switch self {
        case .invalid(let detail): return detail.isEmpty ? "Claude Code returned an error. Refresh before retrying." : detail
        case .timeout: return "Claude Code timed out. Check the connection and refresh before retrying."
        }
    }
}

enum ModsRepository {
    static func parse(_ raw: String) throws -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("https://") {
            guard let url = URLComponents(string:text), url.host?.lowercased() == "github.com",
                  url.user == nil, url.password == nil, url.port == nil, url.query == nil, url.fragment == nil else {
                throw ModsError.invalid("Use a public GitHub repository: owner/repo.")
            }
            text = url.path.trimmingCharacters(in:CharacterSet(charactersIn:"/"))
        }
        if text.hasSuffix(".git") { text.removeLast(4) }
        guard text.range(of: #"^[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9][A-Za-z0-9_.-]*$"#, options:.regularExpression) != nil,
              !text.split(separator:"/").contains(where: { $0 == "." || $0 == ".." }) else {
            throw ModsError.invalid("Use a public GitHub repository: owner/repo.")
        }
        return text
    }
}

struct ModListing: Codable, Identifiable {
    let pluginID: String
    let name: String
    let description: String
    let author: String
    let url: String
    let tags: [String]
    var catalogSource: String? = nil
    var category: String? = nil
    var sourcePath: String? = nil
    var id: String { pluginID }
    var sourceID: String { catalogSource ?? ModsCatalog.repository }
    var repository: String? { try? ModsRepository.parse(url) }
    var categoryKey: String { category ?? tags.first ?? "other" }
    var sourceURL: URL? {
        guard let repo = repository else { return nil }
        var result = URL(string:"https://github.com/" + repo)!
        if let path = sourcePath, let source = ModsCatalog.sources.first(where: { $0.id == sourceID }) {
            result.appendPathComponent("tree/" + source.branch + "/" + path)
        }
        return result
    }
}

struct ModCatalogSource: Identifiable {
    let repository: String
    let name: String
    let marketplace: String
    let license: String
    var branch = "main"
    var id: String { repository }
    var manifestURL: URL { URL(string:"https://raw.githubusercontent.com/\(repository)/\(branch)/.claude-plugin/marketplace.json")! }
}

enum ModsCatalog {
    static let repository = "omarcevi/claudemods"
    static let marketplace = "claudemods"
    static let directoryURL = URL(string:"https://raw.githubusercontent.com/omarcevi/claudemods/main/data/mods.json")!
    static let marketplaceURL = URL(string:"https://raw.githubusercontent.com/omarcevi/claudemods/main/.claude-plugin/marketplace.json")!
    static let sources: [ModCatalogSource] = [
        .init(repository:repository,name:"ClaudeMods",marketplace:marketplace,license:"CC0 1.0"),
        .init(repository:"whyashthakker/awesome-claude-code-mods",name:"Awesome Mods",marketplace:"awesome-claude-code-mods",license:"MIT"),
        .init(repository:"hamzafer/claude-code-mods",name:"Hamza's Mods",marketplace:"claude-code-mods",license:"MIT"),
        .init(repository:"T-AI-Labs/claude-code-mods",name:"T-AI-Labs",marketplace:"T-AI-Labs",license:"MIT")
    ]

    private struct DirectoryEntry: Decodable {
        let name: String; let type: String; let url: String
        let author: String; let description: String; let tags: [String]?
    }
    private struct Source: Decodable {
        let repository: String?
        let path: String?
        init(from decoder: Decoder) throws {
            let box = try decoder.singleValueContainer()
            if let value = try? box.decode([String:String].self) {
                repository = value["repo"] ?? value["url"]
                path = nil
            } else { repository = nil; path = try? box.decode(String.self) }
        }
    }
    private struct Author: Decodable {
        let name: String?
        init(from decoder: Decoder) throws {
            let box = try decoder.singleValueContainer()
            if let text = try? box.decode(String.self) { name = text }
            else { name = (try? box.decode([String:String].self))?["name"] }
        }
    }
    private struct Plugin: Decodable {
        let name: String; let description: String?; let source: Source
        let author: Author?; let category: String?; let tags: [String]?
    }
    private struct Marketplace: Decodable { let name: String; let plugins: [Plugin]; let owner: Author? }

    static func decode(directory: Data, marketplace: Data) throws -> [ModListing] {
        guard directory.count <= 2_000_000, marketplace.count <= 2_000_000 else { throw ModsError.invalid("Catalog is too large.") }
        let decoder = JSONDecoder()
        let entries = try decoder.decode([DirectoryEntry].self, from:directory).filter { $0.type == "mod" }
        let market = try decoder.decode(Marketplace.self, from:marketplace)
        guard market.name == Self.marketplace else { throw ModsError.invalid("Unexpected marketplace name.") }
        var results: [ModListing] = []; var seen = Set<String>()
        for plugin in market.plugins {
            guard let raw = plugin.source.repository, let repo = try? ModsRepository.parse(raw),
                  let entry = entries.first(where: { (try? ModsRepository.parse($0.url).lowercased()) == repo.lowercased() }) else { continue }
            let id = plugin.name + "@" + market.name
            guard ModOperation.validID(id), seen.insert(id).inserted else { continue }
            results.append(ModListing(pluginID:id, name:plugin.name, description:plugin.description ?? entry.description,
                author:entry.author, url:"https://github.com/" + repo, tags:entry.tags ?? []))
        }
        guard !results.isEmpty else { throw ModsError.invalid("No installable Mods were found. The previous catalog is preserved.") }
        return results.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func decodeManifest(_ data: Data, source: ModCatalogSource) throws -> [ModListing] {
        guard data.count <= 2_000_000 else { throw ModsError.invalid("Catalog is too large.") }
        let market = try JSONDecoder().decode(Marketplace.self,from:data)
        guard market.name == source.marketplace else { throw ModsError.invalid("Unexpected marketplace name for \(source.repository).") }
        var results: [ModListing] = []; var seen = Set<String>()
        for plugin in market.plugins {
            let id = plugin.name + "@" + market.name
            guard ModOperation.validID(id), seen.insert(id).inserted else { continue }
            var repo: String; var path: String?
            if let remote = plugin.source.repository, let parsed = try? ModsRepository.parse(remote) { repo = parsed }
            else if let raw = plugin.source.path,
                    raw.hasPrefix("./"), raw.range(of:#"^[A-Za-z0-9_./-]+$"#,options:.regularExpression) != nil,
                    !raw.split(separator:"/").contains("..") {
                repo = source.repository; path = String(raw.dropFirst(2))
            } else { continue }
            results.append(ModListing(pluginID:id,name:plugin.name,description:plugin.description ?? "",author:plugin.author?.name ?? market.owner?.name ?? source.repository.split(separator:"/").first.map(String.init) ?? "",url:"https://github.com/"+repo,tags:plugin.tags ?? [],catalogSource:source.id,category:plugin.category,sourcePath:path))
        }
        guard !results.isEmpty else { throw ModsError.invalid("No installable Mods in \(source.repository). The saved catalog is preserved.") }
        return results
    }

    /// Each successful cached source replaces only its own bundle partition.
    static func merge(bundled: [ModListing], cached: [ModListing]) -> [ModListing] {
        let updated = Set(cached.map(\.sourceID))
        var seen = Set<String>()
        return (bundled.filter { !updated.contains($0.sourceID) } + cached).filter { seen.insert($0.id).inserted }
    }

    static func repositoryToAdd(for source: ModCatalogSource, registered: [ModMarketplace]) throws -> String? {
        guard let existing = registered.first(where: { $0.name == source.marketplace }) else { return source.repository }
        let actual = existing.repo.flatMap { try? ModsRepository.parse($0) }
            ?? existing.source.flatMap { try? ModsRepository.parse($0) }
        guard actual?.lowercased() == source.repository.lowercased() else {
            throw ModsError.invalid("Marketplace '\(source.marketplace)' is already registered to a different or unverified source. Expected \(source.repository). Check it in Claude Code before installing. / 市场名称冲突，请先在 Claude Code 中确认仓库来源。")
        }
        return nil
    }
}

struct ModRepositoryStats: Codable {
    let stars: Int
    let pushedAt: Date?
    let fetchedAt: Date
    static func decode(_ data: Data, now: Date = Date()) throws -> Self {
        struct Response: Decodable { let stargazers_count: Int; let pushed_at: Date? }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let value = try decoder.decode(Response.self,from:data)
        guard value.stargazers_count >= 0 else { throw ModsError.invalid("Invalid repository statistics.") }
        return Self(stars:value.stargazers_count,pushedAt:value.pushed_at,fetchedAt:now)
    }
}

struct ModsQuery: Equatable {
    enum Sort: String, CaseIterable { case stars, updated, name, localViews }
    enum State: String, CaseIterable { case all, installed, notInstalled }
    var search = ""
    var source = ""
    var category = ""
    var state = State.all
    var sort = Sort.stars

    func apply(_ entries: [ModListing], installedIDs: Set<String>, statistics: [String:ModRepositoryStats], views: [String:Int]) -> [ModListing] {
        let text = search.trimmingCharacters(in:.whitespacesAndNewlines)
        return entries.filter { entry in
            (source.isEmpty || entry.sourceID == source) && (category.isEmpty || entry.categoryKey == category) &&
            (state == .all || (installedIDs.contains(entry.id) == (state == .installed))) &&
            (text.isEmpty || ([entry.name,entry.description,entry.author,entry.pluginID,entry.sourceID,entry.categoryKey] + entry.tags).contains { $0.localizedCaseInsensitiveContains(text) })
        }.sorted { lhs,rhs in
            let left = lhs.repository.flatMap { statistics[$0.lowercased()] }
            let right = rhs.repository.flatMap { statistics[$0.lowercased()] }
            switch sort {
            case .stars:
                if left?.stars != right?.stars { return (left?.stars ?? -1) > (right?.stars ?? -1) }
            case .updated:
                let l = left?.pushedAt?.timeIntervalSince1970 ?? -.infinity
                let r = right?.pushedAt?.timeIntervalSince1970 ?? -.infinity
                if l != r { return l > r }
            case .localViews:
                if views[lhs.id,default:0] != views[rhs.id,default:0] { return views[lhs.id,default:0] > views[rhs.id,default:0] }
            case .name: break
            }
            let order = lhs.name.localizedStandardCompare(rhs.name)
            return order == .orderedSame ? lhs.id < rhs.id : order == .orderedAscending
        }
    }
}

struct InstalledMod: Decodable, Identifiable {
    let pluginID: String
    let scope: String
    let version: String
    let enabled: Bool
    let projectPath: String?
    var id: String { pluginID + ":" + scope + ":" + (projectPath ?? "") }
    var isUser: Bool { scope == "user" }
    enum CodingKeys: String, CodingKey { case pluginID = "id", scope, version, enabled, projectPath }
}

struct ModMarketplace: Decodable, Identifiable {
    let name: String
    let source: String?
    let repo: String?
    var id: String { name }
}

struct AvailableMod: Decodable, Identifiable {
    let pluginId: String
    let name: String
    let description: String?
    let marketplaceName: String
    var id: String { pluginId }
}

enum ModsSnapshot {
    static func decodePlugins(_ data: Data) throws -> [InstalledMod] {
        let decoder = JSONDecoder()
        if let array = try? decoder.decode([InstalledMod].self, from:data) { return array }
        struct Wrapped: Decodable { let installed: [InstalledMod] }
        return try decoder.decode(Wrapped.self, from:data).installed
    }
    static func decodeAvailable(_ data: Data) throws -> [AvailableMod] {
        struct Wrapped: Decodable { let available: [AvailableMod] }
        return try JSONDecoder().decode(Wrapped.self, from:data).available
    }
}

struct ModOperation: Identifiable, Equatable {
    enum Kind: String, CaseIterable { case install, enable, disable, update, uninstall }
    let kind: Kind
    let pluginID: String
    var id: String { pluginID }
    static func validID(_ value: String) -> Bool {
        value.range(of:#"^[A-Za-z0-9][A-Za-z0-9_.-]*@[A-Za-z0-9][A-Za-z0-9_.-]*$"#, options:.regularExpression) != nil
    }
    static func supportsLifecycle(_ value: String) -> Bool {
        validID(value) && !value.hasSuffix("@skills-dir")
    }
    func arguments() throws -> [String] {
        guard Self.supportsLifecycle(pluginID) else { throw ModsError.invalid("This entry must be managed in Claude Code's own plugin manager.") }
        var args = ["plugin",kind.rawValue,pluginID,"--scope","user","--json"]
        if kind == .uninstall { args.append("--keep-data") }
        return args
    }
    func refreshArguments() throws -> [String]? {
        guard Self.validID(pluginID) else { throw ModsError.invalid("Invalid plugin identifier.") }
        guard kind == .update, let marketplace = pluginID.split(separator:"@").last else { return nil }
        return ["plugin","marketplace","update",String(marketplace),"--json"]
    }
}

struct ModsCommandResult {
    let code: Int32
    let output: String
}

struct ModsCLI {
    let executable: URL
    var environment: [String:String] = [:]
    var timeout: TimeInterval = 120

    static func supportsMods(_ version: String) -> Bool {
        guard let range = version.range(of:#"\b[0-9]+\.[0-9]+\.[0-9]+\b"#, options:.regularExpression) else { return false }
        let numbers = version[range].split(separator:".").compactMap { Int($0) }
        return numbers.count == 3 && !numbers.lexicographicallyPrecedes([2,1,287])
    }

    static func discover() -> URL? {
        let env = ProcessInfo.processInfo.environment
        let explicit = env["CLAUDEFONT_CLAUDE_CLI"].map { [$0] } ?? []
        let paths = explicit + [NSHomeDirectory()+"/.local/bin/claude", "/opt/homebrew/bin/claude", "/usr/local/bin/claude"] +
            (env["PATH"] ?? "").split(separator:":").filter { !$0.isEmpty }.map { String($0)+"/claude" }
        return paths.first(where: { FileManager.default.isExecutableFile(atPath:$0) }).map { URL(fileURLWithPath:$0) }
    }

    func run(_ arguments: [String]) async throws -> ModsCommandResult {
        try await Task.detached(priority:.userInitiated) {
            let process = Process(); process.executableURL = executable; process.arguments = arguments
            var env = ProcessInfo.processInfo.environment
            env.merge(environment) { _, new in new }
            let standard = [NSHomeDirectory()+"/.local/bin", "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
            env["PATH"] = (standard + [env["PATH"] ?? ""]).joined(separator:":")
            process.environment = env
            // Never borrow the checkout's project/local plugin scopes.
            process.currentDirectoryURL = URL(fileURLWithPath:NSHomeDirectory())
            process.standardInput = FileHandle.nullDevice
            let logURL = FileManager.default.temporaryDirectory.appendingPathComponent("claude-font-mods-"+UUID().uuidString)
            guard FileManager.default.createFile(atPath:logURL.path, contents:nil, attributes:[.posixPermissions:0o600]) else {
                throw ModsError.invalid("Could not create the command log.")
            }
            let log = try FileHandle(forUpdating:logURL)
            defer { try? log.close(); try? FileManager.default.removeItem(at:logURL) }
            process.standardOutput = log; process.standardError = log
            let deadline = Date().addingTimeInterval(timeout)
            let timer = DispatchWorkItem {
                if process.isRunning {
                    process.terminate()
                    DispatchQueue.global().asyncAfter(deadline:.now()+2) {
                        if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                    }
                }
            }
            try process.run()
            DispatchQueue.global().asyncAfter(deadline:.now()+timeout, execute:timer)
            process.waitUntilExit(); timer.cancel()
            if Date() >= deadline { throw ModsError.timeout }
            try log.seek(toOffset:0)
            let output = try log.read(upToCount:12_000_001) ?? Data()
            guard output.count <= 12_000_000 else { throw ModsError.invalid("Command output is too large.") }
            return ModsCommandResult(code:process.terminationStatus, output:String(decoding:output, as:UTF8.self))
        }.value
    }
}
