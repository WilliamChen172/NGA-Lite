//
//  HomeViewModel.swift
//  NGA
//
//  Created by William Chen on 3/13/26.
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var recmThreads: [HomeRecmTopic] = []
    @Published private(set) var hotThreads: [HomeRecmTopic] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let apiClient = APIClient.shared

    /// 当前 tab 的帖子：0=关注(空), 1=推荐, 2=热帖
    func threads(for tab: Int) -> [HomeRecmTopic] {
        switch tab {
        case 1: return recmThreads
        case 2: return hotThreads
        default: return []
        }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let recmTask = apiClient.fetchRecmThreads()
            async let hotTask = apiClient.fetchHotThreads()
            let (recm, hot) = try await (recmTask, hotTask)
            recmThreads = recm
            hotThreads = hot
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
