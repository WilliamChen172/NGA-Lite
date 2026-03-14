//
//  PostContentParser.swift
//  NGA
//
//  解析 NGA 帖子 content（BBCode + HTML 实体）为可展示的富文本片段。
//  支持 [b]/[url]/[img]/[quote]、简单 HTML、自闭合表情 [s:xx:yy]。
//

import Foundation

// MARK: - 解析结果类型

/// 解析后的内容片段，供 PostContentView 渲染
enum PostContentSegment: Equatable {
    case text(String)
    case bold(String)
    case link(url: String, text: String)
    case image(url: String)
    case quote(String)
    case newline
}

struct PostContentParser {
    private static let imageBase = "https://img.nga.178.com/attachments/"

    // MARK: - 公开接口

    /// 从 content 中提取所有图片 URL，用于列表缩略图等
    static func extractImageUrls(from content: String?) -> [String] {
        parse(content).compactMap { seg in
            if case .image(let url) = seg { return url }
            return nil
        }
    }

    /// 解析原始 content 为展示用片段数组
    static func parse(_ raw: String?) -> [PostContentSegment] {
        guard var s = raw, !s.isEmpty else { return [] }
        
        s = decodeHTMLEntities(s)
        s = s.replacingOccurrences(of: "<br/>", with: "\n")
        s = s.replacingOccurrences(of: "<br>", with: "\n")
        s = s.replacingOccurrences(of: "<br />", with: "\n")
        s = normalizeSimpleHTML(s)
        
        return parseBBCode(s)
    }

    // MARK: - 预处理

    /// 将简单 HTML 标签转为 BBCode（如 reply 框内的 &lt;b&gt;...&lt;/b&gt;）
    private static func normalizeSimpleHTML(_ s: String) -> String {
        var r = s
        r = r.replacingOccurrences(of: "<b>", with: "[b]")
        r = r.replacingOccurrences(of: "</b>", with: "[/b]")
        r = r.replacingOccurrences(of: "<i>", with: "[i]")
        r = r.replacingOccurrences(of: "</i>", with: "[/i]")
        r = r.replacingOccurrences(of: "<u>", with: "[u]")
        r = r.replacingOccurrences(of: "</u>", with: "[/u]")
        return r
    }
    
    private static func decodeHTMLEntities(_ s: String) -> String {
        var r = s
        let entities: [(String, String)] = [
            ("&lt;", "<"), ("&gt;", ">"), ("&amp;", "&"), ("&quot;", "\""),
            ("&nbsp;", " "), ("&#39;", "'"), ("&#x27;", "'")
        ]
        for (ent, ch) in entities {
            r = r.replacingOccurrences(of: ent, with: ch)
        }
        return r
    }

    // MARK: - BBCode 解析

    private static func parseBBCode(_ s: String) -> [PostContentSegment] {
        var segments: [PostContentSegment] = []
        var i = s.startIndex
        
        while i < s.endIndex {
            if s[i] == "[" {
                if let (newSegs, end) = parseTag(s, from: i) {
                    segments.append(contentsOf: newSegs)
                    if let last = newSegs.last, case .quote(let q) = last, !q.isEmpty {
                        segments.append(.newline)
                    }
                    i = end
                    continue
                }
                // Failed to parse tag (e.g. unclosed [quote]); treat "[" as literal to avoid infinite loop
                segments.append(.text("["))
                i = s.index(after: i)
                continue
            }
            
            if s[i] == "\n" {
                segments.append(.newline)
                i = s.index(after: i)
                continue
            }
            
            var textStart = i
            while i < s.endIndex, s[i] != "[" && s[i] != "\n" {
                i = s.index(after: i)
            }
            let text = String(s[textStart..<i])
            if !text.isEmpty {
                segments.append(.text(text))
            }
        }
        return segments
    }

    /// 解析单个 BBCode 标签（含自闭合 NGA 表情）
    private static func parseTag(_ s: String, from start: String.Index) -> ([PostContentSegment], String.Index)? {
        guard start < s.endIndex, s[start] == "[" else { return nil }
        var i = s.index(after: start)
        
        var tagName = ""
        var paramVal = ""
        while i < s.endIndex, s[i] != " " && s[i] != "=" && s[i] != "]" {
            tagName.append(s[i])
            i = s.index(after: i)
        }
        
        if i < s.endIndex && s[i] == "=" {
            i = s.index(after: i)
            var depth = 0
            while i < s.endIndex {
                if s[i] == "]" && depth == 0 { break }
                if s[i] == "[" { depth += 1 }
                else if s[i] == "]" { depth -= 1 }
                paramVal.append(s[i])
                i = s.index(after: i)
            }
        }
        
        while i < s.endIndex && s[i] != "]" {
            i = s.index(after: i)
        }
        guard i < s.endIndex else { return nil }
        let tagEnd = s.index(after: i)
        
        let closingTag = "[/\(tagName)]"
        if let closeRange = s.range(of: closingTag, range: tagEnd..<s.endIndex) {
            let inner = String(s[tagEnd..<closeRange.lowerBound])
            let afterClose = closeRange.upperBound
            
            switch tagName.lowercased() {
            case "b":
                return ([.bold(inner)], afterClose)
            case "i", "u":
                return ([.text(inner)], afterClose)
            case "url":
                var url = paramVal.isEmpty ? inner : paramVal
                if url.hasPrefix("/") && !url.hasPrefix("//") {
                    url = "https://ngabbs.com" + url
                }
                return ([.link(url: url, text: inner.isEmpty ? url : inner)], afterClose)
            case "img":
                let path = inner.trimmingCharacters(in: .whitespaces)
                var fullPath = path
                if !path.hasPrefix("http") {
                    fullPath = path.hasPrefix("./") ? String(path.dropFirst(2)) : path
                    fullPath = imageBase + fullPath
                }
                return ([.image(url: fullPath)], afterClose)
            case "quote":
                return ([.quote(inner)], afterClose)
            case "collapse":
                return ([.quote(inner)], afterClose)
            case "color", "size":
                return (parseBBCode(inner), afterClose)
            case "pid", "uid":
                return ([.text(inner)], afterClose)
            default:
                if tagName.hasPrefix("s:") {
                    return ([.text("")], afterClose)
                }
                return ([.text(inner)], afterClose)
            }
        }
        // 自闭合 NGA 表情标签 [s:a2:偷吃]，无 [/...] 结尾，直接消费并替换为空
        if tagName.hasPrefix("s:") {
            return ([.text("")], tagEnd)
        }
        return nil
    }
}
