//
//  ThreadRowView.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI
import Kingfisher

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

            // Image preview (below title, max height, keep aspect ratio, small corner radius)
            if let urlStr = thread.firstImageUrl, let url = URL(string: urlStr) {
                ZStack(alignment: .topTrailing) {
                    KFImage(url)
                        .placeholder { placeholder }
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: AppTheme.Layout.threadPreviewImageMaxHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.threadPreviewImageCornerRadius))
                    if thread.imageCount > 1 {
                        Text("\(thread.imageCount)图")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .padding(6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
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

    private var placeholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 80)
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
            lastPost: nil,
            firstImageUrl: "https://img.nga.178.com/attachments/mon_201910/26/aQ5-fnqgK4ToS79-24.jpg",
            imageCount: 3
        ))
    }
}
