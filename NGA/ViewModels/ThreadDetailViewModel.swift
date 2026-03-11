//
//  ThreadDetailViewModel.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import Combine

@MainActor
final class ThreadDetailViewModel: ObservableObject {
    @Published private(set) var posts: [Post] = []
    @Published private(set) var currentPage = 1
    @Published private(set) var totalPages = 1
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isPosting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoginRequired = false

    private let forumService: any ForumServiceProtocol
    private var threadId: Int = 0

    init(forumService: any ForumServiceProtocol = ForumService.shared) {
        self.forumService = forumService
    }

    func loadThread(threadId: Int) async {
        self.threadId = threadId
        currentPage = 1
        isLoading = true
        errorMessage = nil
        isLoginRequired = false

        do {
            posts = try await forumService.getThread(threadId: threadId, page: 1)
        } catch AppError.loginRequired {
            isLoginRequired = true
            errorMessage = AppError.loginRequired.errorDescription
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadNextPage() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true

        do {
            let newPosts = try await forumService.getThread(threadId: threadId, page: currentPage + 1)
            if !newPosts.isEmpty {
                posts.append(contentsOf: newPosts)
                currentPage += 1
            }
        } catch AppError.loginRequired {
            isLoginRequired = true
            errorMessage = AppError.loginRequired.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    func votePost(postId: Int, tid: Int, pid: Int, upvote: Bool) async {
        let value = upvote ? 1 : 2
        do {
            let delta = try await forumService.votePost(tid: tid, pid: pid, value: value)
            if let idx = posts.firstIndex(where: { $0.id == postId }) {
                let p = posts[idx]
                let newScore = (p.score ?? 0) + (upvote ? delta : 0)
                let newScore2 = (p.score2 ?? 0) + (upvote ? 0 : delta)
                posts[idx] = p.withScores(score: newScore, score2: newScore2)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createReply(content: String, replyTo: Int? = nil) async throws {
        isPosting = true
        errorMessage = nil

        defer { isPosting = false }

        do {
            let post = try await forumService.reply(threadId: threadId, content: content, replyTo: replyTo)
            posts.append(post)
        } catch let error as AppError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
