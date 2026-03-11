//
//  PostRowView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI
import SwiftSoup

struct PostRowView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let floor = post.floor {
                    Text("#\(floor)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                if let author = post.author {
                    Text(author)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
            }

            if let content = post.content {
                Text(plainText(from: content))
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }

    private func plainText(from html: String) -> String {
        do {
            let doc = try SwiftSoup.parse(html)
            return try doc.text()
        } catch {
            return html
        }
    }
}
