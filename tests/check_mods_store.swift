// SPDX-License-Identifier: GPL-3.0-only
import Foundation

@main struct ModsStoreChecks {
    @MainActor static func main() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let cli = env["MODS_TEST_CLI"], let config = env["MODS_TEST_CONFIG"], let market = env["MODS_TEST_MARKET"] else {
            fatalError("Set the isolated Mods test environment.")
        }
        var count = 0
        func check(_ name: String, _ value: Bool) {
            guard value else { fatalError(name) }; count += 1; print("PASS: " + name)
        }
        let store = ModsStore(executable:URL(fileURLWithPath:cli), environment:["CLAUDE_CONFIG_DIR":config,"CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC":"1"])
        let plugin = "claude-font-fixture@claude-font-fixture-market"
        await store.refresh()
        check("official installed state is readable", store.stateKnown && store.error.isEmpty && store.installed.contains { $0.pluginID == plugin })
        await store.loadAvailable()
        check("custom marketplace exposes uninstalled fixture", store.available.contains { $0.pluginId == "claude-font-second@claude-font-fixture-market" })
        store.enqueue(.disable,plugin); store.enqueue(.enable,plugin)
        check("new intent replaces earlier intent", store.queue.count == 1 && store.queue[0].kind == .enable)
        store.enqueue(.disable,plugin)
        store.enqueue(.install,"missing@claude-font-fixture-market")
        let partial = await store.apply()
        check("partial failure is not success", !partial && !store.error.isEmpty)
        check("completed operation is removed, failed item retained", store.queue.count == 1 && store.queue[0].pluginID.hasPrefix("missing@"))
        check("successful operation is read back and reload is requested", store.installed.first { $0.pluginID == plugin }?.enabled == false && store.needsReload)
        store.queue.removeAll(); store.enqueue(.enable,plugin)
        let enabled = await store.apply()
        check("recovery applies the next explicit request", enabled && store.queue.isEmpty)
        let manifest = URL(fileURLWithPath:market).appendingPathComponent("fixture-plugin/.claude-plugin/plugin.json")
        var json = try JSONSerialization.jsonObject(with:Data(contentsOf:manifest)) as! [String:Any]
        let next = "1.0.\(Int(Date().timeIntervalSince1970))"
        json["version"] = next
        try JSONSerialization.data(withJSONObject:json).write(to:manifest, options:.atomic)
        store.enqueue(.update,plugin)
        let updated = await store.apply()
        check("update refreshes marketplace and reads new version", updated && store.installed.first { $0.pluginID == plugin }?.version == next)
        store.enqueue(.uninstall,plugin)
        let removed = await store.apply()
        check("uninstall removes only the selected user plugin", removed && !store.installed.contains { $0.pluginID == plugin })
        store.enqueue(.install,plugin)
        let installed = await store.apply()
        check("install restores fixture through official CLI", installed && store.installed.contains { $0.pluginID == plugin && $0.isUser })
        let repositoryCount = store.marketplaces.count
        await store.addRepository("../invalid")
        check("invalid repository changes nothing", !store.error.isEmpty && store.marketplaces.count == repositoryCount)
        let unavailable = ModsStore(executable:URL(fileURLWithPath:"/usr/bin/false"))
        await unavailable.refresh()
        unavailable.enqueue(.install,plugin)
        check("unreadable state disables mutations", !unavailable.stateKnown && !unavailable.canMutate && unavailable.queue.isEmpty)
        let temp = URL(fileURLWithPath:config).deletingLastPathComponent().appendingPathComponent("timeout-fixture")
        try FileManager.default.createDirectory(at:temp, withIntermediateDirectories:true)
        let fake = temp.appendingPathComponent("claude")
        let script = """
        #!/bin/sh
        case "$1 $2 $3" in
          "--version  ") echo "${MODS_FAKE_VERSION:-2.1.310 (Claude Code)}";;
          "plugin list --json"|"plugin marketplace list")
            if [ -f "$MODS_TIMEOUT_FLAG" ]; then exit 1; else echo '[]'; fi;;
          "plugin install "*) touch "$MODS_TIMEOUT_FLAG"; exec /bin/sleep 3;;
          *) exit 1;;
        esac
        """
        try Data(script.utf8).write(to:fake)
        try FileManager.default.setAttributes([.posixPermissions:0o700], ofItemAtPath:fake.path)
        let flag = temp.appendingPathComponent(UUID().uuidString).path
        let uncertain = ModsStore(executable:fake, environment:["MODS_TIMEOUT_FLAG":flag], commandTimeout:1)
        await uncertain.refresh()
        check("timeout fixture starts with known state", uncertain.stateKnown)
        uncertain.enqueue(.install,"test@fixture")
        let timedOut = await uncertain.apply()
        check("indeterminate mutation requires successful refresh", !timedOut && !uncertain.stateKnown && !uncertain.canMutate && uncertain.queue.count == 1)
        let old = ModsStore(executable:fake, environment:["MODS_TIMEOUT_FLAG":temp.appendingPathComponent(UUID().uuidString).path,"MODS_FAKE_VERSION":"2.1.267 (Claude Code)"])
        await old.refresh()
        check("old CLI cannot mutate", !old.canMutate)
        await old.addRepository("../invalid"); old.enqueue(.install,"test@fixture")
        check("repository action cannot bypass version gate", !old.canMutate && old.queue.isEmpty)
        print("All \(count) Mods store checks passed")
    }
}
