//
//  ForumService.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import Logging

actor ForumService: ForumServiceProtocol {
    static let shared = ForumService()
    private let apiClient = APIClient.shared
    private let log = Logger.for(.forum)

    private init() {}

    func getForums() async throws -> [Forum] {
        log.debug("getForums()")
        do {
            let response: ForumCategoryAPIResponse = try await apiClient.request(
                endpoint: .homeCategory
            )
            let forums = Self.flattenForums(from: response)
            log.info("getForums() -> \(forums.count) forums")
            return forums
        } catch {
            log.error("getForums() failed: \(error.localizedDescription)")
            throw error
        }
    }

    private static func flattenForums(from response: ForumCategoryAPIResponse) -> [Forum] {
        var forums: [Forum] = []
        for category in response.result ?? [] {
            for group in category.groups ?? [] {
                for item in group.forums ?? [] {
                    forums.append(Forum(
                        fid: item.fid.intValue,
                        name: item.name,
                        name2: nil,
                        description: item.info,
                        parent: group.id,
                        subForums: nil
                    ))
                }
            }
        }
        return forums
    }

    func getForumCategories() async throws -> [ForumCategoryDisplay] {
        log.debug("getForumCategories()")
        do {
            let json = try await apiClient.requestJSON(endpoint: .homeCategory)
            let response: ForumCategoryAPIResponse = try JSONDecoder().decode(ForumCategoryAPIResponse.self, from: JSONSerialization.data(withJSONObject: json))
            return Self.buildForumCategories(from: response)
        } catch {
            log.error("getForumCategories() failed: \(error.localizedDescription)")
            throw error
        }
    }

    private static func buildForumCategories(from response: ForumCategoryAPIResponse) -> [ForumCategoryDisplay] {
        var result: [ForumCategoryDisplay] = []
        for (catIndex, category) in (response.result ?? []).enumerated() {
            let catName = category.name ?? ""
            var groups: [ForumGroupDisplay] = []
            for (groupIndex, group) in (category.groups ?? []).enumerated() {
                let forums = (group.forums ?? []).map { item in
                    Forum(
                        fid: item.fid.intValue,
                        name: item.name,
                        name2: nil,
                        description: item.info,
                        parent: group.id,
                        subForums: nil
                    )
                }
                if !forums.isEmpty {
                    // Use index-based IDs to avoid ForEach id collision (same id = SwiftUI reuses wrong views)
                    let groupId = 2_000_000 + catIndex * 10000 + groupIndex
                    groups.append(ForumGroupDisplay(
                        id: groupId,
                        name: group.name,
                        forums: forums
                    ))
                }
            }
            if !groups.isEmpty {
                let catId = 1_000_000 + catIndex
                result.append(ForumCategoryDisplay(id: catId, name: catName, groups: groups))
            }
        }
        return result
    }

    func getThreads(forumId: Int, page: Int = 1, orderBy: String? = Constants.API.orderByLastPost) async throws -> [ForumThread] {
        log.debug("getThreads forumId=\(forumId) page=\(page) orderBy=\(orderBy ?? "default")")
        do {
            let list = try await apiClient.fetchThreadList(fid: forumId, page: page, orderBy: orderBy ?? Constants.API.orderByLastPost)
            log.info("getThreads forumId=\(forumId) page=\(page) -> \(list.count) threads")
            return list
        } catch {
            log.error("getThreads forumId=\(forumId) failed: \(error.localizedDescription)")
            throw error
        }
    }

    func votePost(tid: Int, pid: Int, value: Int) async throws -> Int {
        try await apiClient.votePost(tid: tid, pid: pid, value: value)
    }

    func getThread(threadId: Int, page: Int = 1) async throws -> [Post] {
        log.debug("getThread threadId=\(threadId) page=\(page)")
        do {
            let list = try await apiClient.fetchPostList(tid: threadId, page: page)
            log.info("getThread threadId=\(threadId) page=\(page) -> \(list.count) posts")
            return list
        } catch {
            log.error("getThread threadId=\(threadId) failed: \(error.localizedDescription)")
            throw error
        }
    }

    func createThread(forumId: Int, title: String, content: String) async throws -> ForumThread {
        log.debug("createThread forumId=\(forumId) title=\(title.prefix(30))...")
        do {
            let body: [String: String] = [
                "fid": "\(forumId)",
                "subject": title,
                "content": content
            ]
            let response: PostNewResponse = try await apiClient.request(
                endpoint: .postNew,
                body: body
            )
            guard let thread = response.dataThread else {
                log.error("createThread decoding failed")
                throw AppError.decodingFailed
            }
            log.info("createThread forumId=\(forumId) -> tid=\(thread.tid)")
            return thread
        } catch {
            log.error("createThread failed: \(error.localizedDescription)")
            throw error
        }
    }

    func reply(threadId: Int, content: String, replyTo: Int? = nil) async throws -> Post {
        log.debug("reply threadId=\(threadId) replyTo=\(replyTo ?? 0)")
        do {
            var body: [String: String] = [
                "tid": "\(threadId)",
                "content": content
            ]
            if let replyTo = replyTo {
                body["repid"] = "\(replyTo)"
            }
            let response: PostReplyResponse = try await apiClient.request(
                endpoint: .postReply,
                body: body
            )
            guard let post = response.dataPost else {
                log.error("reply decoding failed")
                throw AppError.decodingFailed
            }
            log.info("reply threadId=\(threadId) -> pid=\(post.pid)")
            return post
        } catch {
            log.error("reply threadId=\(threadId) failed: \(error.localizedDescription)")
            throw error
        }
    }
}
