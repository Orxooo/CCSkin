// Copyright (C) 2026 Orxooo
// SPDX-License-Identifier: GPL-3.0-only
import Foundation

@main struct FrameworkIntegrityChecks {
    static func main() throws {
        var count = 0
        func check(_ name: String, _ value: Bool) throws {
            guard value else { throw EngineError(name) }; count += 1; print("PASS: " + name)
        }
        // A minimal arm64 Mach-O with a single named digest section.
        var bytes = Data(repeating:0,count:250)
        func u32(_ offset:Int, _ value:UInt32) {
            for i in 0..<4 { bytes[offset+i] = UInt8(truncatingIfNeeded:value >> (8*i)) }
        }
        u32(0,0xfeedfacf);u32(4,0x0100000c);u32(16,1);u32(20,152)
        u32(32,0x19);u32(36,152);u32(96,1)
        bytes.replaceSubrange(104..<120,with:Data("__asar_integrity".utf8))
        bytes.replaceSubrange(120..<136,with:Data("__DATA_CONST\0\0\0\0".utf8))
        u32(144,66);u32(152,184)
        bytes.replaceSubrange(184..<216,with:FrameworkIntegrity.sentinel)
        bytes[216]=1;bytes[217]=1
        try check("reads the named digest slot",try FrameworkIntegrity.digestRange(bytes)==218..<250)
        var unused=bytes;unused[216]=0
        try check("does not enable an unused slot",try FrameworkIntegrity.digestRange(unused)==nil)
        var future=bytes;future[217]=2
        do { _ = try FrameworkIntegrity.digestRange(future);throw EngineError("accepted unknown version") }
        catch { try check("unknown digest versions refuse modification",String(describing:error).contains("Unsupported Electron integrity digest version")) }
        var truncated=bytes;truncated.removeLast()
        do { _ = try FrameworkIntegrity.digestRange(truncated);throw EngineError("accepted truncated slot") }
        catch { try check("truncated digest slot rejected",String(describing:error).contains("Unsupported Electron integrity slot")) }
        let table:[String:Any] = ["ElectronAsarIntegrity":[
            "Resources/ion-dist.asar":["algorithm":"SHA256","hash":String(repeating:"b",count:64)],
            "Resources/app.asar":["algorithm":"SHA256","hash":String(repeating:"a",count:64)]]]
        // Independently calculated with Python hashlib over sorted path/algorithm/hash.
        let expected = "674320674a1d660308d704e81a35ae58da2343de28cbc8e72df1951542818dd1"
        try check("digest covers both archive paths algorithms and hashes",try FrameworkIntegrity.tableDigest(table).map{String(format:"%02x",$0)}.joined()==expected)
        let temporary=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".app")
        defer { try? FileManager.default.removeItem(at:temporary) }
        let fixture=temporary.appendingPathComponent("Contents/Frameworks/Electron Framework.framework/Electron Framework")
        try FileManager.default.createDirectory(at:fixture.deletingLastPathComponent(),withIntermediateDirectories:true)
        bytes.replaceSubrange(218..<250,with:try FrameworkIntegrity.tableDigest(table))
        try bytes.write(to:fixture)
        try FileManager.default.setAttributes([.posixPermissions:0o755],ofItemAtPath:fixture.path)
        var next=table
        var entries=table["ElectronAsarIntegrity"] as! [String:[String:Any]]
        entries["Resources/app.asar"]!["hash"]=String(repeating:"c",count:64)
        next["ElectronAsarIntegrity"]=entries
        try check("updates the populated digest",try FrameworkIntegrity.update(temporary,from:table,to:next))
        let updated=try Data(contentsOf:fixture)
        try check("preserves all bytes outside the digest including enabled and version",updated.prefix(218)==bytes.prefix(218) && updated.count==bytes.count)
        try check("updated digest matches the new table",try updated.subdata(in:218..<250)==FrameworkIntegrity.tableDigest(next))
        try check("preserves executable mode",try FileManager.default.attributesOfItem(atPath:fixture.path)[.posixPermissions] as? Int == 0o755)
        do { _ = try FrameworkIntegrity.update(temporary,from:table,to:next);throw EngineError("accepted mismatching original") }
        catch { try check("mismatching original digest fails before writing",String(describing:error).contains("does not match") && (try Data(contentsOf:fixture))==updated) }
        if CommandLine.arguments.count > 1 {
        let app=URL(fileURLWithPath:CommandLine.arguments[1])
        let binary=try FrameworkIntegrity.binary(app)!
        let info=try PropertyListSerialization.propertyList(from:Data(contentsOf:app.appendingPathComponent("Contents/Info.plist")),format:nil) as! [String:Any]
        let actual=try Data(contentsOf:binary,options:.mappedIfSafe)
        let range=try FrameworkIntegrity.digestRange(actual)!
        try check("installed Claude digest matches the unmodified ASAR table",try actual.subdata(in:range)==FrameworkIntegrity.tableDigest(info))
        }
        print("All \(count) framework integrity checks passed")
    }
}
