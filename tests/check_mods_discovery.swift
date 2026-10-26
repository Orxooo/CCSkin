// SPDX-License-Identifier: GPL-3.0-only
import Foundation

@main struct ModsDiscoveryChecks {
    @MainActor static func main() async throws {
        var count = 0
        func check(_ name: String, _ value: Bool) {
            guard value else { fatalError(name) }; count += 1; print("PASS: " + name)
        }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("CcSkin-discovery-"+UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:temp) }
        let fetch: @Sendable (URL) async throws -> Data = { url in
            if url.host == "api.github.com" { return Data(#"{"stargazers_count":17,"pushed_at":"2026-10-24T12:00:00Z"}"#.utf8) }
            if url.path.contains("whyashthakker/") {
                return Data(#"{"name":"awesome-claude-code-mods","plugins":[{"name":"desk","source":"./mods/desk","category":"session"}]}"#.utf8)
            }
            if url.path.contains("T-AI-Labs/") {
                return Data(#"{"name":"T-AI-Labs","plugins":[{"name":"meter","source":"./meter"}]}"#.utf8)
            }
            throw ModsError.invalid("fixture source unavailable")
        }
        let store = ModsStore(executable:URL(fileURLWithPath:"/usr/bin/false"),storageDirectory:temp,fetch:fetch)
        let old = ModListing(pluginID:"old@claudemods",name:"Old",description:"",author:"",url:"https://github.com/owner/old",tags:[])
        store.catalog = [old]
        await store.refreshCatalog()
        check("partial refresh keeps failed source entries", store.catalog.contains { $0.id == old.id })
        check("independent successful sources are added", store.catalog.count == 3)
        check("catalog failure does not trust CLI state", !store.stateKnown && !store.canMutate)
        let reloaded = ModsStore(executable:URL(fileURLWithPath:"/usr/bin/false"),storageDirectory:temp,fetch:fetch)
        check("multi-source snapshot survives restart", reloaded.catalog.count == 3)
        await store.refreshStatistics()
        check("repository metrics deduplicate and cache", store.statistics.count == 3 && store.statistics.values.allSatisfy { $0.stars == 17 })
        let refreshed = ModsStore(executable:URL(fileURLWithPath:"/usr/bin/false"),storageDirectory:temp,fetch:fetch)
        check("metrics are available offline after restart", refreshed.statistics.count == 3)
        store.recordView(old); store.recordView(old)
        check("explicit detail opens count per plugin", store.views[old.id] == 2)
        let history = ModsStore(executable:URL(fileURLWithPath:"/usr/bin/false"),storageDirectory:temp,fetch:fetch)
        check("local browsing count persists", history.views[old.id] == 2)
        check("browsing does not enqueue or mutate CLI", store.queue.isEmpty && !store.needsReload)
        let broken = ModsStore(executable:URL(fileURLWithPath:"/usr/bin/false"),storageDirectory:temp,fetch: { _ in throw ModsError.invalid("offline") })
        broken.catalog = [old]
        broken.statistics = ["owner/old":.init(stars:4,pushedAt:nil,fetchedAt:Date(timeIntervalSince1970:0))]
        await broken.refreshStatistics()
        check("failed metric refresh preserves known snapshot", broken.statistics["owner/old"]?.stars == 4)
        check("failed refresh does not fabricate unknown metrics", broken.statistics.count == 1)
        let fake = temp.appendingPathComponent("claude")
        let changed = temp.appendingPathComponent("changed")
        let mutated = temp.appendingPathComponent("mutated")
        let script = """
        #!/bin/sh
        case "$1 $2 $3" in
          "--version  ") echo '2.1.310 (Claude Code)';;
          "plugin list --json") echo '[]';;
          "plugin marketplace list")
            if [ -f "$MODS_CHANGED" ]; then
              echo '[{"name":"awesome-claude-code-mods","source":"github","repo":"other/repo"}]'
            else
              echo '[{"name":"awesome-claude-code-mods","source":"github","repo":"whyashthakker/awesome-claude-code-mods"}]'
            fi;;
          "plugin install "*) touch "$MODS_MUTATED"; echo '{}';;
          *) exit 1;;
        esac
        """
        try Data(script.utf8).write(to:fake)
        try FileManager.default.setAttributes([.posixPermissions:0o700],ofItemAtPath:fake.path)
        let collision = ModsStore(executable:fake,environment:["MODS_CHANGED":changed.path,"MODS_MUTATED":mutated.path],storageDirectory:temp)
        collision.catalog = [ModListing(pluginID:"desk@awesome-claude-code-mods",name:"desk",description:"",author:"",url:"https://github.com/whyashthakker/awesome-claude-code-mods",tags:[],catalogSource:ModsCatalog.sources[1].id)]
        await collision.refresh()
        check("marketplace initially has the expected source", collision.canMutate)
        try Data().write(to:changed)
        collision.enqueue(.install,"desk@awesome-claude-code-mods")
        let applied = await collision.apply()
        check("changed marketplace identity blocks installation before mutation", !applied && !FileManager.default.fileExists(atPath:mutated.path) && collision.queue.count == 1)
        print("All \(count) discovery checks passed")
    }
}
