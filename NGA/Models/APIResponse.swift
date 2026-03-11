//
//  APIResponse.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let code: Int?
    let message: String?
    let data: T?

    var isSuccess: Bool {
        (code ?? 0) == 0
    }
}

struct ForumCategoryResponse: Decodable {
    let result: [Forum]?
}

/// subject/list returns: { code, msg, result: { data: [threads], subForum: [] } }
/// Per NGA App API: https://github.com/wolfcon/NGA-API-Documents
struct ThreadListResponse: Decodable {
    let code: Int?
    let msg: String?
    let result: ThreadListResult?

    var threadsList: [ForumThread] {
        result?.data ?? []
    }
}

struct ThreadListResult: Decodable {
    let data: [ForumThread]?

    enum CodingKeys: String, CodingKey {
        case data
        case subForum
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = try c.decodeIfPresent([ForumThread].self, forKey: .data)
        // subForum omitted; not needed for thread list display
    }
}

struct ThreadDetailResponse: Decodable {
    let result: [Post]?
    let data: [Post]?
    let posts: [Post]?

    var postsList: [Post] {
        result ?? data ?? posts ?? []
    }
}

struct PostNewResponse: Decodable {
    let data: ForumThread?
    let result: ForumThread?
    let tid: Int?

    var dataThread: ForumThread? {
        data ?? result ?? (tid.map { ForumThread(tid: $0, fid: 0, subject: "", authorId: nil, author: nil, postDate: nil, replyCount: nil, lastPost: nil) })
    }
}

struct PostReplyResponse: Decodable {
    let data: Post?
    let result: Post?
    let pid: Int?

    var dataPost: Post? {
        data ?? result ?? (pid.map { Post(pid: $0, tid: 0, fid: 0, content: nil, authorId: nil, author: nil, floor: nil, postDate: nil) })
    }
}
