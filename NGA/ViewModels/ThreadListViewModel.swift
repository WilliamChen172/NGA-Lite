//
//  ThreadListViewModel.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import Combine

/// thread.php order_by 合法值
enum ThreadSortOrder: String, CaseIterable {
    case lastPost = "lastpostdesc"   // 最后回复
    case postDate = "postdatedesc"   // 发布时间

    var displayName: String {
        switch self {
        case .lastPost: return "最后回复"
        case .postDate: return "发布时间"
        }
    }
}

@MainActor
final class ThreadListViewModel: ObservableObject {
    @Published private(set) var threads: [ForumThread] = []
    @Published private(set) var currentPage = 1
    @Published private(set) var totalPages = 1
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoginRequired = false
    @Published var sortOrder: ThreadSortOrder = .lastPost

    private let forumService: any ForumServiceProtocol
    private var forumId: Int = 0

    init(forumService: any ForumServiceProtocol = ForumService.shared) {
        self.forumService = forumService
    }

    func loadThreads(forumId: Int) async {
        self.forumId = forumId
        currentPage = 1
        isLoading = true
        errorMessage = nil
        isLoginRequired = false

        do {
            threads = try await forumService.getThreads(forumId: forumId, page: 1, orderBy: sortOrder.rawValue)
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
            let newThreads = try await forumService.getThreads(forumId: forumId, page: currentPage + 1, orderBy: sortOrder.rawValue)
            if !newThreads.isEmpty {
                threads.append(contentsOf: newThreads)
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

    func switchSortOrder(_ order: ThreadSortOrder) async {
        guard order != sortOrder else { return }
        sortOrder = order
        await loadThreads(forumId: forumId)
    }
}
