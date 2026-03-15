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
    var posts: [Post] = []
    var rowIndex: Int? = nil
    var fetchPostByPid: ((Int) async throws -> Post?)? = nil
    var onVoteUp: (() -> Void)?
    var onVoteDown: (() -> Void)?

    @State private var displayContent: String?

    /// 优先用 post.author（帖子本身可能带作者名），其次 authorInfo，无则 UID:xxx
    private var displayName: String { post.author ?? authorInfo?.displayName ?? (post.authorId.map { "UID:\($0)" } ?? "匿名") }
    private var levelText: String { authorInfo?.levelName.map { "级别:\($0)" } ?? "级别:-" }
    private var prestigeText: String {
        guard let n = authorInfo?.displayReputation else { return "威望:-" }
        return "威望:\(n)"
    }
    private var postCountText: String {
        guard let n = authorInfo?.postnum else { return "发帖:-" }
        return "发帖:\(n)"
    }
    
    /// 根据 from_client 返回设备图标名称
    private var deviceIconName: String {
        guard let fc = post.fromClient?.lowercased() else { return "iphone" }
        if fc.contains("ios") { return "apple.logo" }
        if fc.contains("android") { return "square.grid.2x2" }
        return "iphone"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Author header
            HStack(spacing: AppTheme.Layout.mediumSpacing) {
                // Avatar
                avatarView
                
                // Author info
                VStack(alignment: .leading, spacing: 6) {
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
                    
                    // Metadata: 级别 / 威望 / 发帖
                    HStack(spacing: AppTheme.Layout.mediumSpacing) {
                        Text(levelText)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                        Text("·")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text(prestigeText)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                        Text("·")
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text(postCountText)
                            .font(.system(size: AppTheme.FontSize.caption))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, AppTheme.Layout.standardPadding)
            .padding(.top, AppTheme.Layout.standardPadding)
            
            // Post content (BBCode + HTML entities parsed, B1 引用补全)
            Group {
                if let content = displayContent ?? post.content {
                    PostContentView(content: content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Layout.standardPadding)
                        .padding(.top, AppTheme.Layout.standardSpacing)
                }
            }
            .task(id: post.pid) {
                guard post.content != nil, fetchPostByPid != nil else { return }
                let postsByPid = Dictionary(uniqueKeysWithValues: posts.map { ($0.pid, $0) })
                displayContent = await PostContentParser.completeB1Content(
                    raw: post.content,
                    postsByPid: postsByPid,
                    fetchPostByPid: fetchPostByPid
                )
            }
            
            // Timestamp
            HStack {
                Spacer()
                if let postDate = post.postDate {
                    Text(TimeFormatter.formatFullDateTime(postDate))
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: deviceIconName)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.Layout.standardPadding)
            .padding(.top, AppTheme.Layout.standardSpacing)
            .padding(.bottom, AppTheme.Layout.smallSpacing)
            
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
        .background(rowIndex.map { idx in idx == 0 ? AppTheme.Colors.contentBackground : (idx % 2 == 1 ? AppTheme.Colors.postRowOdd : AppTheme.Colors.contentBackground) } ?? AppTheme.Colors.contentBackground)
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
                postDate: Int(Date().timeIntervalSince1970),
                fromClient: "7 iOS"
            ),
            authorInfo: UserInForum(
                user: User(uid: 1, username: "永结桐心", nickname: nil, avatar: nil),
                forumContext: ForumUserContext(fid: 1, levelName: "学徒", postnum: 352, fame: 1200)
            )
        )
    }
}
