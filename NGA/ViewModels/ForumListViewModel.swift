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
    @Published private(set) var favorForums: [Forum] = []
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
            async let catsTask = forumService.getForumCategories()
            async let favorTask = forumService.getFavorForums()
            let (cats, favor) = try await (catsTask, favorTask)
            categories = cats
            favorForums = favor
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
