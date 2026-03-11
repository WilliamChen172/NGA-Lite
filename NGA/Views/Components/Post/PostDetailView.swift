//
//  PostDetailView.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    var onVoteUp: (() -> Void)?
    var onVoteDown: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Author header
            HStack(spacing: AppTheme.Layout.mediumSpacing) {
                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: AppTheme.Layout.avatarSize, height: AppTheme.Layout.avatarSize)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: AppTheme.FontSize.title3))
                    }
                
                // Author info
                VStack(alignment: .leading, spacing: 4) {
                    if let author = post.author {
                        HStack(spacing: 6) {
                            Text(author)
                                .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Metadata: level, prestige, posts
                    HStack(spacing: AppTheme.Layout.smallSpacing) {
                        Text("级别:学徒")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                        
                        Text("威望:1")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                        
                        Text("发帖:352")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Follow button
                Button {
                    // Follow action - not implemented in MVP
                } label: {
                    Text("关注")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(AppTheme.Colors.accent)
                        .padding(.horizontal, AppTheme.Layout.standardPadding)
                        .padding(.vertical, 6)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppTheme.Colors.accent, lineWidth: 1)
                        }
                }
            }
            .padding(.horizontal, AppTheme.Layout.standardPadding)
            .padding(.top, AppTheme.Layout.standardPadding)
            
            // Post content
            if let content = post.content {
                Text(content)
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Layout.standardPadding)
                    .padding(.top, AppTheme.Layout.mediumSpacing)
            }
            
            // Timestamp
            HStack {
                Spacer()
                if let postDate = post.postDate {
                    Text(TimeFormatter.formatFullDateTime(postDate))
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "iphone")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.Layout.standardPadding)
            .padding(.top, AppTheme.Layout.smallSpacing)
            
            // Action bar
            HStack(spacing: 32) {
                PostActionButton(icon: "gift")
                VoteButton(
                    icon: "hand.thumbsup",
                    count: post.score ?? 0,
                    action: onVoteUp
                )
                VoteButton(
                    icon: "hand.thumbsdown",
                    count: post.score2 ?? 0,
                    action: onVoteDown
                )
                
                Spacer()
                
                PostActionButton(icon: "bubble.left")
                PostActionButton(icon: "plus")
            }
            .padding(.horizontal, AppTheme.Layout.standardPadding)
            .padding(.vertical, AppTheme.Layout.mediumSpacing)
        }
        .background(AppTheme.Colors.contentBackground)
    }
}

struct VoteButton: View {
    let icon: String
    let count: Int
    let action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: AppTheme.FontSize.title3))
                    .foregroundColor(.gray)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        PostDetailView(post: Post(
            pid: 1,
            tid: 1,
            fid: 1,
            content: "这是一条测试内容，用于展示帖子详情页面的布局效果。可以包含多行文本。",
            authorId: 1,
            author: "永结桐心",
            floor: 1,
            postDate: Int(Date().timeIntervalSince1970)
        ))
    }
}
