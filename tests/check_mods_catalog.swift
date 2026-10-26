// SPDX-License-Identifier: GPL-3.0-only
import Foundation

@main struct ModsCatalogChecks {
    static func main() throws {
        var count = 0
        func check(_ name: String, _ value: Bool) {
            guard value else { fatalError(name) }
            count += 1; print("PASS: " + name)
        }
        check("four distinct source namespaces", ModsCatalog.sources.count == 4 && Set(ModsCatalog.sources.map(\.marketplace)).count == 4)
        let source = ModsCatalog.sources[1]
        let data = Data(#"{"name":"awesome-claude-code-mods","owner":{"name":"Author"},"plugins":[{"name":"desk","description":"Desktop utility","source":"./mods/desk","category":"session"},{"name":"escape","source":"../outside"},{"name":"remote","source":{"source":"github","repo":"other/remote"}},{"name":"desk","source":"./mods/desk"}]}"#.utf8)
        let entries = try ModsCatalog.decodeManifest(data, source:source)
        check("manifest entries deduplicate and reject escaping paths", entries.count == 2)
        let desk = entries.first { $0.name == "desk" }!
        check("source identity and author retained", desk.sourceID == source.id && desk.author == "Author")
        check("relative plugins use their host repository", desk.repository == source.repository)
        check("external plugins use their own repository", entries.first { $0.name == "remote" }?.repository == "other/remote")
        check("wrong manifest cannot register another marketplace", (try? ModsCatalog.decodeManifest(Data(#"{"name":"other","plugins":[]}"#.utf8),source:source)) == nil)
        let legacy = try JSONDecoder().decode(ModListing.self, from:Data(#"{"pluginID":"legacy@claudemods","name":"Legacy","description":"Old cache","author":"owner","url":"https://github.com/owner/repo","tags":["safety"]}"#.utf8))
        check("legacy snapshots retain source identity", legacy.sourceID == ModsCatalog.repository)
        check("new bundled sources survive legacy cache", ModsCatalog.merge(bundled:entries, cached:[legacy]).count == 3)
        let cached = ModListing(pluginID:desk.pluginID,name:desk.name,description:"New description",author:desk.author,url:desk.url,tags:desk.tags,catalogSource:source.id,category:desk.category)
        check("cached source replaces its bundle partition", ModsCatalog.merge(bundled:entries,cached:[cached]).count == 1)
        let stats: [String:ModRepositoryStats] = [source.repository.lowercased():.init(stars:25,pushedAt:Date(timeIntervalSince1970:20),fetchedAt:Date()),"other/remote":.init(stars:2,pushedAt:Date(timeIntervalSince1970:30),fetchedAt:Date())]
        let all = entries + [legacy]
        var query = ModsQuery()
        check("stars rank known repositories before missing data", query.apply(all,installedIDs:[],statistics:stats,views:[:]).map(\.name) == ["desk","remote","Legacy"])
        query.sort = .updated
        check("repository activity uses pushed time", query.apply(all,installedIDs:[],statistics:stats,views:[:]).first?.name == "remote")
        query.sort = .localViews
        check("local views use this plugin's detail count", query.apply(all,installedIDs:[],statistics:stats,views:[legacy.id:4]).first?.id == legacy.id)
        query.source = source.id; query.search = "utility"; query.state = .installed
        check("source search and installed filters compose", query.apply(all,installedIDs:[desk.id],statistics:stats,views:[:]).map(\.id) == [desk.id])
        query.category = "safety"
        check("category participates in the same filter", query.apply(all,installedIDs:[desk.id],statistics:stats,views:[:]).isEmpty)
        query = ModsQuery(); query.state = .notInstalled
        check("not installed excludes only installed identities", query.apply(all,installedIDs:[desk.id],statistics:stats,views:[:]).count == 2)
        let tied = ModRepositoryStats(stars:0,pushedAt:nil,fetchedAt:Date())
        check("real zero ranks before unknown", ModsQuery().apply(all,installedIDs:[],statistics:[source.repository.lowercased():tied],views:[:]).first?.id == desk.id)
        let decoded = try ModRepositoryStats.decode(Data(#"{"stargazers_count":42,"pushed_at":"2026-10-24T12:00:00Z"}"#.utf8))
        check("GitHub metrics preserve real stars and timestamp", decoded.stars == 42 && decoded.pushedAt != nil)
        check("missing stars are not fabricated as zero", (try? ModRepositoryStats.decode(Data("{}".utf8))) == nil)
        check("unregistered source returns exact repository", try ModsCatalog.repositoryToAdd(for:source,registered:[]) == source.repository)
        let matching = ModMarketplace(name:source.marketplace,source:"github",repo:source.repository)
        check("registered matching source needs no add", try ModsCatalog.repositoryToAdd(for:source,registered:[matching]) == nil)
        let collision = ModMarketplace(name:source.marketplace,source:"github",repo:"wrong/repository")
        var rejected = false
        do { _ = try ModsCatalog.repositoryToAdd(for:source,registered:[collision]) } catch { rejected = true }
        check("namespace collision cannot silently install wrong source", rejected)
        print("All \(count) catalog checks passed")
    }
}
