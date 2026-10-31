// Copyright (C) 2026 Orxooo
// SPDX-License-Identifier: GPL-3.0-only
import Foundation

// A finite renderer-resource adapter for xterm's public constructor options.
// It changes the options before xterm measures its canvas and character grid.
enum TerminalResource {
    static let marker = "/* claudefont-terminal-1 */"
    static let externalMarker = "/* claudefont-terminal-props-1 */"
    struct ExternalResource {
        let path: String
        let text: String
        let props: [NSTextCheckingResult]
        var archiveEntry: String? = nil
    }
    // Current Claude passes measured font options to ShellTerminal in ion-dist.
    // Patch both the loading placeholder and live props, leaving zoom calculation
    // and React hook/memoization logic intact.
    static func externalResources(_ resources: URL) throws -> [ExternalResource] {
        let relative = "ion-dist/assets/v1"
        let directory = resources.appendingPathComponent(relative)
        let identifier = #"[A-Za-z_$][A-Za-z0-9_$]*"#
        // New renderers pass font preferences into the size helper: hC(_,v).
        let arguments = identifier + "(?:," + identifier + ")*"
        let pattern = "fontFamily:(" + identifier + "),fontSize:(" + identifier + "(?:\\((?:" + arguments + ")?\\))?)(?=[,}])"
        let regex = try NSRegularExpression(pattern:pattern)
        let archiveURL = resources.appendingPathComponent("ion-dist.asar")
        if exists(archiveURL) {
            let archive = try Archive(url:archiveURL)
            return try archive.entries.keys.sorted().filter { $0.hasPrefix("assets/v1/") && $0.hasSuffix(".js") }.compactMap { path in
                let node = archive.entries[path]!
                guard node["link"] == nil, node["unpacked"] as? Bool != true,
                      (node["size"] as? Int ?? 0) <= 30_000_000 else { return nil }
                let text = String(decoding:try archive.read(path),as:UTF8.self)
                guard text.contains("terminal-pane-placeholder"), text.contains("ShellTerminalChunk") else { return nil }
                let props = regex.matches(in:text,range:NSRange(text.startIndex...,in:text))
                guard text.contains(externalMarker) || props.count == 2 else { return nil }
                return ExternalResource(path:"ion-dist.asar",text:text,props:props,archiveEntry:path)
            }
        }
        guard exists(directory) else { return [] }
        try noSymlink(directory)
        return try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil)
            .filter { $0.pathExtension == "js" }.sorted { $0.path < $1.path }.compactMap { file in
                try noSymlink(file)
                let attributes = try FileManager.default.attributesOfItem(atPath:file.path)
                guard attributes[.type] as? FileAttributeType == .typeRegular,
                      (attributes[.size] as? NSNumber)?.intValue ?? 0 <= 30_000_000 else { return nil }
                let text = try String(contentsOf:file,encoding:.utf8)
                guard text.contains("terminal-pane-placeholder"), text.contains("ShellTerminalChunk") else { return nil }
                let props = regex.matches(in:text,range:NSRange(text.startIndex...,in:text))
                guard text.contains(externalMarker) || props.count == 2 else { return nil }
                return ExternalResource(path:relative + "/" + file.lastPathComponent,text:text,props:props)
            }
    }
    static func externalReplacements(_ resources: URL, settings: [String:Any]) throws -> [String:Data] {
        let found = try externalResources(resources)
        guard !found.isEmpty else { return [:] }
        try require(found.count == 1 && !found[0].text.contains(externalMarker),
                    "External terminal resource structure is unknown or ambiguous; restore terminal defaults")
        let resource = found[0], changed = NSMutableString(string:resource.text)
        let family = settings["code_font_terminal"] as? String ?? ""
        let prefix = family.isEmpty ? "" : "\"" + family + "\","
        let encoded = try JSONSerialization.data(withJSONObject:[prefix])
        let literal = String(String(decoding:encoded,as:UTF8.self).dropFirst().dropLast())
        let scale = StyleSchema.cssNumber(StyleSchema.number(settings,"code_scale_terminal")/100)
        for match in resource.props.reversed() {
            let original = resource.text as NSString
            let font = original.substring(with:match.range(at:1))
            let size = original.substring(with:match.range(at:2))
            changed.replaceCharacters(in:match.range,with:"fontFamily:" + (family.isEmpty ? font : "(" + literal + "+" + font + ")") + ",fontSize:(" + size + ")*" + scale)
        }
        let replacement = Data((externalMarker + "\n" + (changed as String)).utf8)
        if let entry = resource.archiveEntry {
            let archive = try Archive(url:resources.appendingPathComponent(resource.path))
            return [resource.path:try archive.replacing([entry:replacement])]
        }
        return [resource.path:replacement]
    }
    static func optionsRange(_ text:String) -> Range<String.Index>? {
        guard text.contains("xterm"), !text.contains(marker) else { return nil }
        let regex = try! NSRegularExpression(pattern:#"new\s+[A-Za-z_$][A-Za-z0-9_$]*\s*\(\s*\{"#)
        var matches:[Range<String.Index>] = []
        for found in regex.matches(in:text,range:NSRange(text.startIndex...,in:text)) {
            guard let prefix = Range(found.range,in:text),let start = text[prefix].lastIndex(of:"{") else { continue }
            var index = start, depth = 0, quote:Character?, escaping = false
            var finish:String.Index?
            while index < text.endIndex {
                let character = text[index]
                if let active = quote {
                    if escaping { escaping = false }
                    else if character == "\\" { escaping = true }
                    else if character == active { quote = nil }
                } else if character == "\"" || character == "'" || character == "`" { quote = character }
                else if character == "{" { depth += 1 }
                else if character == "}" { depth -= 1; if depth == 0 { finish = text.index(after:index); break } }
                index = text.index(after:index)
            }
            guard let finish else { continue }
            let range = start..<finish, object = String(text[range])
            // Comments and regular expressions need a full JavaScript parser; reject them.
            guard !object.contains("//"), !object.contains("/*"), !object.contains("/"),
                  object.range(of:#"\ballowProposedApi\s*:\s*true\b"#,options:.regularExpression) != nil,
                  object.range(of:#"\bfontSize\s*:"#,options:.regularExpression) != nil else { continue }
            matches.append(range)
        }
        return matches.count == 1 ? matches[0] : nil
    }
    static func candidates(_ archive:Archive, excluding main:String) throws -> [(String,String,Range<String.Index>)] {
        var output:[(String,String,Range<String.Index>)] = []
        for name in archive.entries.keys.sorted() where name != main && name.hasPrefix(".vite/renderer/") && name.hasSuffix(".js") {
            let node = archive.entries[name]!
            guard node["link"] == nil, (node["size"] as? Int ?? 0) <= 30_000_000 else { continue }
            let bytes = try archive.read(name)
            guard let text = String(data:bytes,encoding:.utf8), let range = optionsRange(text) else { continue }
            try require(node["unpacked"] as? Bool != true,"Terminal adapter requires a packed renderer asset")
            output.append((name,text,range))
        }
        return output
    }
    static func replacements(_ archive:Archive, settings:[String:Any], excluding main:String) throws -> [String:Data] {
        let found = try candidates(archive,excluding:main)
        try require(found.count == 1,"Terminal resource structure is unknown or ambiguous; restore terminal defaults")
        let (name,text,range) = found[0], object = String(text[range])
        let family = settings["code_font_terminal"] as? String ?? ""
        let fontJSON = String(decoding:try JSONSerialization.data(withJSONObject:[family],options:[.fragmentsAllowed]),as:UTF8.self)
        let literal = String(fontJSON.dropFirst().dropLast())
        let scale = StyleSchema.cssNumber(StyleSchema.number(settings,"code_scale_terminal")/100)
        let familyRule = family.isEmpty ? "" : "fontFamily:" + literal + ","
        let replacement = marker + "((options)=>({...options," + familyRule + "fontSize:(Number.isFinite(options.fontSize)?options.fontSize:15)*" + scale + "}))(" + object + ")"
        let changed = text.replacingCharacters(in:range,with:replacement)
        return [name:Data(changed.utf8)]
    }
}
