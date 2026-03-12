//
//  ForumCard.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

/// 版块卡片：横向布局，图标固定左侧，名称右侧（参考网页版，适配 SwiftUI / Liquid Glass 美学）
struct ForumCard: View {
    let forum: Forum

    private let iconSize = AppTheme.Layout.forumCardIconSize

    var body: some View {
        HStack(spacing: 12) {
            avatarView
            nameLabel
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: AppTheme.Layout.forumCardHeight)
        .background(cardBackground)
    }

    private var avatarView: some View {
        Group {
            if let url = forum.iconURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        fallbackAvatar
                    case .empty:
                        fallbackAvatar
                            .overlay { ProgressView() }
                    @unknown default:
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }
        }
        .frame(width: iconSize, height: iconSize)
        .clipShape(Circle())
    }

    private var fallbackAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        avatarColor.opacity(0.85),
                        avatarColor.opacity(0.65)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: iconSize, height: iconSize)
            .overlay {
                Text(String(forum.name.prefix(1)))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
    }

    private var nameLabel: some View {
        Text(forum.name)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .lineLimit(2)
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(.regularMaterial)
            .shadow(
                color: .black.opacity(0.04),
                radius: 8,
                x: 0,
                y: 2
            )
    }

    private var avatarColor: Color {
        let hash = abs(forum.fid.hashValue)
        return AppTheme.Colors.avatarColors[hash % AppTheme.Colors.avatarColors.count]
    }
}

#Preview {
    ForumCard(forum: MockData.forums[1])
        .padding()
}
