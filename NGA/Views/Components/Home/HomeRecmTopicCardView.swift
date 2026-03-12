//
//  HomeRecmTopicCardView.swift
//  NGA
//
//  Created by William Chen on 3/13/26.
//

import SwiftUI
import Kingfisher

/// 首页推荐帖子卡片（recmd_topic）：图片在上、标题在下，一行两个。
/// 图片 2:1 且 fill 裁剪不拉伸；标题区固定两行高度。
struct HomeRecmTopicCardView: View {
    let card: HomeRecmTopic

    var body: some View {
        VStack(spacing: 0) {
            // 图片区域：2:1 宽高比，fill 裁剪不拉伸
            ZStack(alignment: .topLeading) {
                cardImage
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, minHeight: 0)
                    .clipped()

                // 版块标签：左上角
                if let forum = card.forumName, !forum.isEmpty {
                    Text(forum)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4)
                        .padding(6)
                }

                // 评论数：右下角
                if let count = card.thread.replyCount {
                    HStack(spacing: 2) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 10))
                        Text("\(count)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(6)
                }
            }
            .aspectRatio(AppTheme.Layout.recmTopicImageAspectRatio, contentMode: .fit)
            .clipped()

            // 标题区域：固定两行高度，不随内容变动
            Text(card.thread.subject)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(height: AppTheme.Layout.recmTopicTitleHeight, alignment: .top)
                .background(AppTheme.Colors.cardBackground)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private var cardImage: some View {
        if let urlStr = card.imageUrl, let url = URL(string: urlStr) {
            KFImage(url)
                .placeholder { placeholder }
                .resizable()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [AppTheme.Colors.bannerDecorStart, AppTheme.Colors.bannerDecorEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

#Preview {
    HomeRecmTopicCardView(card: HomeRecmTopic(
        thread: ForumThread(tid: 1, fid: 7, subject: "【讨论】2026年最期待的游戏", authorId: 1, author: "test", postDate: nil, replyCount: 13, lastPost: nil),
        imageUrl: nil,
        forumName: "游戏综合"
    ))
    .frame(width: 175)
    .padding()
}
