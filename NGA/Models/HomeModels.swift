//
//  HomeModels.swift
//  NGA
//
//  Created by William Chen on 3/13/26.
//

import Foundation

/// 首页推荐帖子（recmd_topic）：含 thread 及可选缩略图、版块名
struct HomeRecmTopic: Identifiable {
    let thread: ForumThread
    let imageUrl: String?
    let forumName: String?

    var id: Int { thread.tid }
}

/// 首页轮播项
struct HomeBannerItem: Identifiable {
    let id: String
    let imageUrl: String
    let title: String?
    let link: String?
}
