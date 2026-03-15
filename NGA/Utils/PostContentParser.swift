//
//  PostContentParser.swift
//  NGA
//
//  解析 NGA 帖子 content（BBCode + HTML 实体）为可展示的富文本片段。
//  支持 [b]/[url]/[img]/[quote]、简单 HTML、自闭合表情 [s:xx:yy]。
//

import Foundation

// MARK: - 引用头结构

/// 引用头元数据，用于 B1 补全或引用头可点击
struct ReplyHeader {
    let pid: Int
    let uid: Int?
    let author: String
    let date: String
}

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
        let (normalized, _) = extractAndReplaceReplyHeaders(s)
        
        return parseBBCode(normalized)
    }
    
    /// 提取并替换 B1/B2 引用头，返回 (归一化字符串, 引用头元数据)
    /// - B1: content 开头，无 [quote]，替换为可读文本
    /// - B2: [quote] 内，替换为可读文本
    static func extractAndReplaceReplyHeaders(_ s: String) -> (normalized: String, replyHeader: ReplyHeader?) {
        var result = s
        var header: ReplyHeader?
        
        // B1: content 开头 [b]Reply to [pid=...]...Post by [uid=...]...[/uid] (date)[/b]
        // 经 normalizeSimpleHTML 后已为 [b]
        let b1Pattern = #"\[b\]Reply to \[pid=(\d+),[^\]]+\]Reply\[/pid\] Post by \[uid=(\d+)\]([^\]]*)\[/uid\] \(([^)]+)\)\[/b\]"#
        if let b1Regex = try? NSRegularExpression(pattern: b1Pattern),
           let m = b1Regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)),
           let pidRange = Range(m.range(at: 1), in: result),
           let uidRange = Range(m.range(at: 2), in: result),
           let authorRange = Range(m.range(at: 3), in: result),
           let dateRange = Range(m.range(at: 4), in: result),
           let fullRange = Range(m.range, in: result) {
            let pid = Int(result[pidRange]) ?? 0
            let uid = Int(result[uidRange])
            let author = String(result[authorRange])
            let date = String(result[dateRange])
            header = ReplyHeader(pid: pid, uid: uid, author: author, date: date)
            let replacement = "▸ Reply to \(author) (\(date)):\n\n"
            result.replaceSubrange(fullRange, with: replacement)
            return (result, header)
        }
        
        // B2: [quote][pid=...]Reply[/pid] [b]Post by [uid=...]...[/uid] (date):[/b]
        let b2Pattern = #"\[quote\]\[pid=(\d+),[^\]]+\]Reply\[/pid\] \[b\]Post by \[uid=(\d+)\]([^\]]*)\[/uid\] \(([^)]+)\):\[/b\]"#
        if let b2Regex = try? NSRegularExpression(pattern: b2Pattern),
           let m = b2Regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)),
           let pidRange = Range(m.range(at: 1), in: result),
           let uidRange = Range(m.range(at: 2), in: result),
           let authorRange = Range(m.range(at: 3), in: result),
           let dateRange = Range(m.range(at: 4), in: result),
           let fullRange = Range(m.range, in: result) {
            let pid = Int(result[pidRange]) ?? 0
            let uid = Int(result[uidRange])
            let author = String(result[authorRange])
            let date = String(result[dateRange])
            header = ReplyHeader(pid: pid, uid: uid, author: author, date: date)
            let replacement = "[quote]▸ Post by \(author) (\(date)):\n\n"
            result.replaceSubrange(fullRange, with: replacement)
        }
        
        return (result, header)
    }

    /// 预处理并提取引用头，供 B1 补全使用。返回 (归一化字符串, 引用头)
    static func preprocessAndExtractReplyHeader(_ raw: String?) -> (normalized: String, replyHeader: ReplyHeader?) {
        guard var s = raw, !s.isEmpty else { return (raw ?? "", nil) }
        s = decodeHTMLEntities(s)
        s = s.replacingOccurrences(of: "<br/>", with: "\n")
        s = s.replacingOccurrences(of: "<br>", with: "\n")
        s = s.replacingOccurrences(of: "<br />", with: "\n")
        s = normalizeSimpleHTML(s)
        return extractAndReplaceReplyHeaders(s)
    }

    /// B1 补全：若为 B1 格式，从 postsByPid 或 fetch 获取被引用内容，合并后返回
    /// B2 格式（content 已含 [quote]）则直接返回 normalized，不叠加 quote 块
    static func completeB1Content(
        raw: String?,
        postsByPid: [Int: Post],
        fetchPostByPid: ((Int) async throws -> Post?)?
    ) async -> String? {
        guard let raw = raw, !raw.isEmpty else { return raw }
        let (normalized, header) = preprocessAndExtractReplyHeader(raw)
        guard let header = header else { return raw }
        if normalized.hasPrefix("[quote]") {
            return normalized
        }
        var quotedContent = ""
        if let local = postsByPid[header.pid]?.content {
            quotedContent = stripNestedQuotes(from: local)
        } else if let fetch = fetchPostByPid {
            let raw = (try? await fetch(header.pid))?.content ?? ""
            quotedContent = stripNestedQuotes(from: raw)
        }
        // 只要回复正文，不要 "▸ Reply to xxx" 那行（已在 quote 块内展示）
        let replyBodyPrefix = "▸ Reply to \(header.author) (\(header.date)):\n\n"
        let replyBody = normalized.hasPrefix(replyBodyPrefix)
            ? String(normalized.dropFirst(replyBodyPrefix.count))
            : normalized
        let fullContent = "[quote]▸ Post by \(header.author) (\(header.date)):\n\n" + quotedContent + "[/quote]\n\n" + replyBody
        return fullContent
    }

    /// 移除 content 中的嵌套 [quote]...[/quote]，只保留该楼层的直接正文（最后一个 [/quote] 之后的部分）
    private static func stripNestedQuotes(from content: String) -> String {
        guard let lastClose = content.range(of: "[/quote]", options: .caseInsensitive) else {
            return content
        }
        let after = content[lastClose.upperBound...]
        let trimmed = after.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ""
        }
        return String(after)
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
        
        // 闭合标签 [/xxx] 直接消费，不当作开标签解析
        if tagName.hasPrefix("/") {
            return ([], tagEnd)
        }

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
        // 未闭合的 [quote]/[collapse]：取剩余内容为 body，避免裸显
        if tagName.lowercased() == "quote" || tagName.lowercased() == "collapse" {
            let inner = String(s[tagEnd...])
            return ([.quote(inner)], s.endIndex)
        }
        return nil
    }
}
