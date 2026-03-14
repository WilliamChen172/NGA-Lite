//
//  PostDetailView.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    var authorInfo: UserInForum?
    var onVoteUp: (() -> Void)?
    var onVoteDown: (() -> Void)?

    private var displayName: String { authorInfo?.displayName ?? post.author ?? "匿名" }
    private var levelText: String { authorInfo?.levelName.map { "级别:\($0)" } ?? "级别:-" }
    private var prestigeText: String {
        guard let n = authorInfo?.displayReputation else { return "威望:-" }
        return "威望:\(n)"
    }
    private var postCountText: String {
        guard let n = authorInfo?.postnum else { return "发帖:-" }
        return "发帖:\(n)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Author header
            HStack(spacing: AppTheme.Layout.mediumSpacing) {
                // Avatar
                avatarView
                
                // Author info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.system(size: AppTheme.FontSize.body, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if post.authorId != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Metadata: level, prestige, posts
                    HStack(spacing: AppTheme.Layout.smallSpacing) {
                        Text(levelText)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                        
                        Text(prestigeText)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                        
                        Text(postCountText)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.Layout.standardPadding)
            .padding(.top, AppTheme.Layout.standardPadding)
            
            // Post content (BBCode + HTML entities parsed)
            if let content = post.content {
                PostContentView(content: content)
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

    @ViewBuilder
    private var avatarView: some View {
        if let url = authorInfo?.avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    placeholderAvatar
                @unknown default:
                    placeholderAvatar
                }
            }
            .frame(width: AppTheme.Layout.avatarSize, height: AppTheme.Layout.avatarSize)
            .clipShape(Circle())
        } else {
            placeholderAvatar
        }
    }

    private var placeholderAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: AppTheme.Layout.avatarSize, height: AppTheme.Layout.avatarSize)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: AppTheme.FontSize.title3))
            }
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
        PostDetailView(
            post: Post(
                pid: 1,
                tid: 1,
                fid: 1,
                content: "这是一条测试内容，用于展示帖子详情页面的布局效果。可以包含多行文本。",
                authorId: 1,
                author: "永结桐心",
                floor: 1,
                postDate: Int(Date().timeIntervalSince1970)
            ),
            authorInfo: UserInForum(
                user: User(uid: 1, username: "永结桐心", nickname: nil, avatar: nil),
                forumContext: ForumUserContext(fid: 1, levelName: "学徒", postnum: 352, reputation: "61_120")
            )
        )
    }
}
