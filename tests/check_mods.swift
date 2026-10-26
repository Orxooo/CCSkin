// SPDX-License-Identifier: GPL-3.0-only
import Foundation

@main struct ModsChecks {
    static func main() async throws {
        var count = 0
        func check(_ name: String, _ value: Bool) {
            guard value else { fatalError(name) }
            count += 1; print("PASS: \(name)")
        }
        check("GitHub URL normalizes to repository", try ModsRepository.parse("https://github.com/owner/repo.git") == "owner/repo")
        for value in ["--help", "owner/repo;touch x", "https://user:pass@github.com/a/b", "https://example.com/a/b", "a/b/c", "a/../b"] {
            check("reject invalid repository", (try? ModsRepository.parse(value)) == nil)
        }
        let directory = Data(#"[{"id":"old","name":"Friendly","type":"mod","url":"https://github.com/owner/repo","author":"owner","description":"Directory description","tags":["reading"],"bundle":true},{"id":"skill","name":"Skill","type":"skill","url":"https://github.com/other/skill","author":"other","description":"Skill"}]"#.utf8)
        let market = Data(#"{"name":"claudemods","plugins":[{"name":"renamed","description":"Actual plugin","source":{"source":"github","repo":"owner/repo","sha":"abc"}},{"name":"skill","source":{"source":"github","repo":"other/skill"}},{"name":"renamed","source":{"source":"github","repo":"owner/repo"}}]}"#.utf8)
        let catalog = try ModsCatalog.decode(directory: directory, marketplace: market)
        check("join on source rather than directory id", catalog.count == 1 && catalog[0].id == "renamed@claudemods")
        check("source description retained", catalog[0].description == "Actual plugin")
        check("wrong marketplace rejected", (try? ModsCatalog.decode(directory: directory, marketplace: Data(#"{"name":"unexpected","plugins":[]}"#.utf8))) == nil)
        let entries = try ModsSnapshot.decodePlugins(Data(#"[{"id":"test@source","scope":"user","version":"1","enabled":true},{"id":"test@source","scope":"project","version":"2","enabled":false}]"#.utf8))
        check("scope collisions retain distinct identities", entries.count == 2 && entries[0].id != entries[1].id)
        check("available response wrapper supported", try ModsSnapshot.decodePlugins(Data(#"{"installed":[],"available":[]}"#.utf8)).isEmpty)
        check("malformed state fails instead of empty success", (try? ModsSnapshot.decodePlugins(Data("{}".utf8))) == nil)
        let op = ModOperation(kind: .disable, pluginID: "test@source")
        check("scope pinned for mutations", try op.arguments() == ["plugin", "disable", "test@source", "--scope", "user", "--json"])
        check("uninstall preserves plugin data", try ModOperation(kind: .uninstall, pluginID: "test@source").arguments().contains("--keep-data"))
        check("command-looking id rejected", (try? ModOperation(kind: .install, pluginID: "--help").arguments()) == nil)
        check("skills directory entries stay outside marketplace lifecycle", (try? ModOperation(kind:.update,pluginID:"test@skills-dir").arguments()) == nil)
        check("supported CLI version recognized", ModsCLI.supportsMods("2.1.310 (Claude Code)"))
        check("minimum CLI version recognized", ModsCLI.supportsMods("2.1.287 (Claude Code)"))
        check("old CLI is not writable", !ModsCLI.supportsMods("2.1.267 (Claude Code)"))
        check("unknown CLI version is not writable", !ModsCLI.supportsMods("unknown"))
        check("id cannot add another argument", (try? ModOperation(kind: .install, pluginID: "test@source --all").arguments()) == nil)
        let result = try await ModsCLI(executable: URL(fileURLWithPath: "/usr/bin/printf")).run(["%s", "literal;$(text)"])
        check("subprocess uses literal arguments", result.output == "literal;$(text)" && result.code == 0)
        let failed = try await ModsCLI(executable: URL(fileURLWithPath: "/usr/bin/false")).run([])
        check("failed command retains exit status", failed.code != 0)
        do {
            _ = try await ModsCLI(executable: URL(fileURLWithPath: "/bin/sleep"), timeout: 0.1).run(["3"])
            fatalError("timeout accepted")
        } catch { check("hung subprocess is bounded", true) }
        if let cli = ProcessInfo.processInfo.environment["MODS_TEST_CLI"],
           let config = ProcessInfo.processInfo.environment["MODS_TEST_CONFIG"] {
            let runner = ModsCLI(executable: URL(fileURLWithPath: cli), environment: ["CLAUDE_CONFIG_DIR":config,"CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC":"1"])
            let plugin = "claude-font-fixture@claude-font-fixture-market"
            for kind in [ModOperation.Kind.disable, .enable, .update, .uninstall, .install] {
                let result = try await runner.run(try ModOperation(kind:kind, pluginID:plugin).arguments())
                check("official isolated CLI \(kind.rawValue)", result.code == 0)
                let data = try await runner.run(["plugin","list","--json"])
                let state = try ModsSnapshot.decodePlugins(Data(data.output.utf8))
                let item = state.first { $0.pluginID == plugin && $0.scope == "user" }
                if kind == .uninstall { check("uninstall readback", item == nil) }
                else { check("mutation readback", item != nil && item?.enabled == (kind != .disable)) }
            }
        }
        print("All \(count) Mods checks passed")
    }
}
