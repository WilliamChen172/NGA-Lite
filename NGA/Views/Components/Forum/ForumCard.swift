//
//  ForumCard.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

struct ForumCard: View {
    let forum: Forum

    var body: some View {
        VStack(spacing: 10) {
            avatarView
            nameLabel
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cardBackground)
    }

    private var avatarView: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        avatarColor.opacity(0.8),
                        avatarColor.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 50, height: 50)
            .overlay {
                Text(String(forum.name.prefix(1)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
    }

    private var nameLabel: some View {
        Text(forum.name)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.black.opacity(0.8))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
            .fill(AppTheme.Colors.cardBackground)
            .shadow(
                color: .black.opacity(AppTheme.Layout.cardShadowOpacity),
                radius: AppTheme.Layout.cardShadowRadius,
                x: 0,
                y: 1
            )
    }

    private var avatarColor: Color {
        let hash = abs(forum.fid.hashValue)
        return AppTheme.Colors.avatarColors[hash % AppTheme.Colors.avatarColors.count]
    }
}

#Preview {
    ForumCard(forum: Forum(fid: 1, name: "游戏综合", name2: nil, description: nil, parent: nil, subForums: nil))
        .padding()
}
