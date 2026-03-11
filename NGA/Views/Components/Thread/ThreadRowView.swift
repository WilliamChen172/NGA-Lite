//
//  ThreadRowView.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct ThreadRowView: View {
    let thread: ForumThread
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.smallSpacing) {
            // Thread title
            Text(thread.subject)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Metadata row
            HStack(spacing: AppTheme.Layout.smallSpacing) {
                // Author
                if let author = thread.author {
                    Text(author)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time and reply count
                HStack(spacing: 4) {
                    if let postDate = thread.postDate {
                        Text(TimeFormatter.formatRelativeTime(timestamp: postDate))
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                    }
                    
                    if let replyCount = thread.replyCount {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text("\(replyCount)回复")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    List {
        ThreadRowView(thread: ForumThread(
            tid: 1,
            fid: 1,
            subject: "9850x3d+5070ti，fps+追剧五五开，选2k还是4k?",
            authorId: 1,
            author: "永结桐心",
            postDate: Int(Date().timeIntervalSince1970) - 3600,
            replyCount: 12,
            lastPost: nil
        ))
    }
}
