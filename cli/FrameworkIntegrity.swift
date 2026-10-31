// Copyright (C) 2026 Orxooo
// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import CryptoKit

// Electron 41+ authenticates the Info.plist ASAR table inside its Mach-O image.
// Keep the enabled/version bytes intact and replace only the expected digest.
// Format: electron/electron shell/common/asar/integrity_digest.mm.
enum FrameworkIntegrity {
    static let sentinel = Data("AGbevlPCksUGKNL8TSn7wGmJEuJsXb2A".utf8)

    static func signingIdentity(_ configured: String?) throws -> String {
        if let configured {
            try require(configured != "-","A certificate identity is required to preserve Electron Helper library validation")
            return configured
        }
        let result = try checked("/usr/bin/security",["find-identity","-v","-p","codesigning"])
        let text = String(decoding:result.output,as:UTF8.self)
        let regex = try NSRegularExpression(pattern:#"\b([0-9A-Fa-f]{40}) \"(?:Apple Development|Developer ID Application):[^\n]+"#)
        let identities = regex.matches(in:text,range:NSRange(text.startIndex...,in:text)).map {
            (text as NSString).substring(with:$0.range(at:1))
        }
        try require(identities.count == 1,"Set CLAUDEFONT_TARGET_SIGN_IDENTITY to an Apple signing certificate for this Electron version")
        return identities[0]
    }

    static func signDependencies(_ app: URL, identity: String) throws {
        let framework = app.appendingPathComponent("Contents/Frameworks/Electron Framework.framework")
        let libraries = framework.appendingPathComponent("Versions/A/Libraries")
        let args = ["--force","--sign",identity,"--preserve-metadata=identifier,entitlements,flags"]
        if exists(libraries) {
            try noSymlink(libraries)
            for library in try FileManager.default.contentsOfDirectory(at:libraries,includingPropertiesForKeys:nil).sorted(by:{$0.path < $1.path}) where library.pathExtension == "dylib" {
                try noSymlink(library)
                _ = try checked("/usr/bin/codesign",args + [library.path])
            }
        }
        // Electron links these sibling frameworks; Squirrel itself links the
        // first two. Sign the dependency closure before its loaders.
        for name in ["Mantle", "ReactiveObjC", "Squirrel"] {
            let dependency = app.appendingPathComponent("Contents/Frameworks/" + name + ".framework")
            guard exists(dependency) else { continue }
            try noSymlink(dependency)
            _ = try checked("/usr/bin/codesign",args + [dependency.path])
        }
        _ = try checked("/usr/bin/codesign",args + [framework.path])
        // These Electron loaders must share the framework's Team ID. Retain all
        // existing entitlements; do not disable Helper library validation.
        for name in ["Claude Helper", "Claude Helper (GPU)", "Claude Helper (Renderer)", "Claude Helper (Plugin)"] {
            let helper = app.appendingPathComponent("Contents/Frameworks/" + name + ".app")
            guard exists(helper) else { continue }
            try noSymlink(helper)
            _ = try checked("/usr/bin/codesign",args + [helper.path])
        }
    }

    static func tableDigest(_ info: [String:Any]) throws -> Data {
        guard let table = info["ElectronAsarIntegrity"] as? [String:[String:Any]] else {
            throw EngineError("Electron archive integrity table is missing")
        }
        var bytes = Data()
        for path in table.keys.sorted(by: { $0.compare($1,options:.literal) == .orderedAscending }) {
            guard let algorithm = table[path]?["algorithm"] as? String,
                  let hash = table[path]?["hash"] as? String,
                  algorithm == "SHA256", hash.range(of:"^[0-9a-f]{64}$",options:.regularExpression) != nil else {
                throw EngineError("Unsupported Electron archive integrity entry")
            }
            for value in [path,algorithm,hash] { bytes.append(Data(value.utf8)) }
        }
        return Data(SHA256.hash(data:bytes))
    }

    static func digestRange(_ bytes: Data) throws -> Range<Int>? {
        func number(_ start: Int, _ size: Int = 4) throws -> UInt64 {
            try require(start >= 0 && start <= bytes.count - size,"Truncated Electron framework")
            return (0..<size).reduce(UInt64(0)) { $0 | UInt64(bytes[start+$1]) << ($1*8) }
        }
        func name(_ start: Int) -> String {
            String(decoding:bytes[start..<start+16].prefix(while:{$0 != 0}),as:UTF8.self)
        }
        try require(try number(0) == 0xfeedfacf && number(4) == 0x0100000c,
                    "Electron framework requires a supported arm64 Mach-O image")
        let count = Int(try number(16)), end = 32 + Int(try number(20))
        try require(end <= bytes.count && count <= 4096,"Invalid Electron load commands")
        var cursor = 32, slots: [Range<Int>] = []
        for _ in 0..<count {
            let command = try number(cursor), size = Int(try number(cursor+4))
            try require(size >= 8 && cursor + size <= end,"Invalid Electron load command")
            if command == 0x19 {
                try require(size >= 72,"Truncated Electron segment")
                let sections = Int(try number(cursor+64))
                try require(sections <= (size-72)/80,"Truncated Electron sections")
                for index in 0..<sections {
                    let section = cursor + 72 + index*80
                    if name(section) == "__asar_integrity" && name(section+16) == "__DATA_CONST" {
                        let length = try number(section+40,8), offset = Int(try number(section+48))
                        try require(length == 66 && offset <= bytes.count-66,
                                    "Unsupported Electron integrity slot")
                        try require(bytes.subdata(in:offset..<offset+32) == sentinel,
                                    "Electron integrity sentinel does not match")
                        if bytes[offset+32] == 0 { continue } // Legacy unpopulated slot: preserve it.
                        try require(bytes[offset+32] == 1 && bytes[offset+33] == 1,
                                    "Unsupported Electron integrity digest version")
                        slots.append(offset+34..<offset+66)
                    }
                }
            }
            cursor += size
        }
        try require(cursor == end && slots.count <= 1,"Ambiguous Electron integrity slot")
        return slots.first
    }

    static func binary(_ app: URL) throws -> URL? {
        let framework = app.appendingPathComponent("Contents/Frameworks/Electron Framework.framework")
        let link = framework.appendingPathComponent("Electron Framework")
        guard exists(link) else { return nil }
        let file = link.resolvingSymlinksInPath()
        try require(file.path.hasPrefix(framework.standardizedFileURL.path + "/"),
                    "Electron framework resolves outside its bundle")
        try noSymlink(file)
        return file
    }

    static func update(_ app: URL, from old: [String:Any], to new: [String:Any]) throws -> Bool {
        guard let file = try binary(app) else { return false }
        var bytes = try Data(contentsOf:file)
        guard let range = try digestRange(bytes) else { return false }
        try require(try bytes.subdata(in:range) == tableDigest(old),
                    "Electron framework integrity digest does not match the original table")
        let next = try tableDigest(new)
        guard bytes.subdata(in:range) != next else { return false }
        bytes.replaceSubrange(range,with:next)
        let attributes = try FileManager.default.attributesOfItem(atPath:file.path)
        try bytes.write(to:file,options:.atomic)
        if let mode = attributes[.posixPermissions] {
            try FileManager.default.setAttributes([.posixPermissions:mode],ofItemAtPath:file.path)
        }
        return true
    }
}
