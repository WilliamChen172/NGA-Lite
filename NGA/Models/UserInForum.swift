//
//  UserInForum.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import Foundation

/// 用户在版块内的展示组合：身份 + 可选版块上下文
struct UserInForum: Identifiable {
    let user: User
    let forumContext: ForumUserContext?

    var id: Int { user.uid }
    var displayName: String { user.displayName }
    var avatarURL: URL? { user.avatarURL }
    var levelName: String? { forumContext?.levelName }
    var postnum: Int? { forumContext?.postnum }
    var displayReputation: Int? { forumContext?.displayReputation }
}
