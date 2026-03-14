//
//  PostContentView.swift
//  NGA
//
//  渲染 PostContentParser 解析后的帖子内容（富文本、引用块、图片）
//

import SwiftUI
import Kingfisher

struct PostContentView: View {
    let content: String?
    
    private var segments: [PostContentSegment] {
        PostContentParser.parse(content)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(blockLines().enumerated()), id: \.offset) { _, line in
                lineView(for: line)
            }
        }
    }

    // MARK: - 分段与布局

    /// 按换行分块，每块为一段可内联渲染的内容或独立图片
    private func blockLines() -> [[PostContentSegment]] {
        var lines: [[PostContentSegment]] = []
        var current: [PostContentSegment] = []
        for seg in segments {
            switch seg {
            case .newline:
                if !current.isEmpty {
                    lines.append(current)
                    current = []
                }
            case .image:
                if !current.isEmpty {
                    lines.append(current)
                    current = []
                }
                lines.append([seg])
            default:
                current.append(seg)
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }
    
    @ViewBuilder
    private func lineView(for line: [PostContentSegment]) -> some View {
        if line.count == 1, case .image(let url) = line[0] {
            postImage(url: url)
        } else if line.count == 1, case .quote(let q) = line[0] {
            quoteBlock(q)
        } else {
            inlineLine(line)
        }
    }
    
    @ViewBuilder
    private func inlineLine(_ line: [PostContentSegment]) -> some View {
        if let attr = buildAttributedString(from: line) {
            Text(attr)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(.primary)
        }
    }
    
    private func quoteLines(_ text: String) -> [[PostContentSegment]] {
        let segs = PostContentParser.parse(text)
        var lines: [[PostContentSegment]] = []
        var current: [PostContentSegment] = []
        for s in segs {
            if case .newline = s {
                if !current.isEmpty { lines.append(current); current = [] }
            } else { current.append(s) }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    // MARK: - 富文本构建

    private func buildAttributedString(from line: [PostContentSegment]) -> AttributedString? {
        var result = AttributedString()
        for seg in line {
            switch seg {
            case .text(let s):
                result.append(AttributedString(s))
            case .bold(let s):
                var a = AttributedString(s)
                a.inlinePresentationIntent = .stronglyEmphasized
                result.append(a)
            case .link(let urlStr, let text):
                var a = AttributedString(text)
                if let url = URL(string: urlStr) {
                    a.link = url
                }
                result.append(a)
            case .quote(let s):
                result.append(AttributedString(s))
            case .image, .newline:
                break
            }
        }
        return result.characters.isEmpty ? nil : result
    }
    
    private func quoteBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(quoteLines(text).enumerated()), id: \.offset) { _, line in
                if let attr = buildAttributedString(from: line) {
                    Text(attr)
                        .font(.system(size: AppTheme.FontSize.smallBody))
                        .foregroundColor(.secondary)
                }
            }
        }
            .padding(.leading, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.12))
            .overlay(
                Rectangle()
                    .frame(width: 3)
                    .foregroundColor(.gray.opacity(0.5)),
                alignment: .leading
            )
    }
    
    private func postImage(url: String) -> some View {
        Group {
            if let u = URL(string: url) {
                KFImage(u)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay { ProgressView() }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    ScrollView {
        PostContentView(content: """
        [b]加粗文字[/b] 普通文字 [url=https://ngabbs.com]链接[/url]
        &lt;br/&gt;第二行 &amp; 实体
        [quote]引用内容在这里[/quote]
        [img]./mon_201910/26/aQ5-fnqgK4ToS79-24.jpg[/img]
        """)
        .padding()
    }
}
