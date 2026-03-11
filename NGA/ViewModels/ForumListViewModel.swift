//
//  ForumListViewModel.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import Foundation
import Combine

@MainActor
final class ForumListViewModel: ObservableObject {
    @Published private(set) var forums: [Forum] = []
    @Published private(set) var categories: [ForumCategoryDisplay] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let forumService: any ForumServiceProtocol

    init(forumService: any ForumServiceProtocol = ForumService.shared) {
        self.forumService = forumService
    }

    func loadForums() async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await forumService.getForumCategories()
            forums = categories.flatMap { cat in
                cat.groups.flatMap { $0.forums }
            }
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
