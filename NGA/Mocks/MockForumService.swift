//
//  MockForumService.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation

/// Mock implementation of ForumServiceProtocol for previews and unit tests.
actor MockForumService: ForumServiceProtocol {
    func getForums() async throws -> [Forum] {
        try await Task.sleep(nanoseconds: 300_000_000) // Simulate network
        return MockData.forums
    }

    func getForumCategories() async throws -> [ForumCategoryDisplay] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return [
            ForumCategoryDisplay(
                id: 1,
                name: "游戏",
                groups: [
                    ForumGroupDisplay(id: 1, name: "热门游戏", forums: MockData.forums)
                ]
            )
        ]
    }

    func getThreads(forumId: Int, page: Int, orderBy: String? = nil) async throws -> [ForumThread] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockData.threads
    }

    func votePost(tid: Int, pid: Int, value: Int) async throws -> Int {
        1
    }

    func getThread(threadId: Int, page: Int) async throws -> [Post] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return MockData.posts
    }

    func createThread(forumId: Int, title: String, content: String) async throws -> ForumThread {
        MockData.threads[0]
    }

    func reply(threadId: Int, content: String, replyTo: Int?) async throws -> Post {
        MockData.posts[0]
    }
}
