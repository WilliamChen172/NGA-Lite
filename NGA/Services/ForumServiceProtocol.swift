//
//  ForumServiceProtocol.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

/// Protocol for forum data operations. Enables dependency injection and testing.
protocol ForumServiceProtocol {
    func getForums() async throws -> [Forum]
    func getForumCategories() async throws -> [ForumCategoryDisplay]
    /// 收藏版块列表，需登录；未登录返回 []
    func getFavorForums() async throws -> [Forum]
    func getThreads(forumId: Int, page: Int, orderBy: String?) async throws -> [ForumThread]
    func getThread(threadId: Int, page: Int) async throws -> (posts: [Post], authorMap: [Int: UserInForum])
    func votePost(tid: Int, pid: Int, value: Int) async throws -> Int
    func createThread(forumId: Int, title: String, content: String) async throws -> ForumThread
    func reply(threadId: Int, content: String, replyTo: Int?) async throws -> Post
}
