//
//  LoadableView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

/// Reusable container for loading, error, and content states. Reduces boilerplate in list views.
struct LoadableView<Content: View>: View {
    let isLoading: Bool
    let isEmpty: Bool
    let errorMessage: String?
    let loadingMessage: String
    let retryAction: (() -> Void)?
    let isLoginRequired: Bool
    let loginAction: (() -> Void)?
    @ViewBuilder let content: () -> Content

    init(
        isLoading: Bool,
        isEmpty: Bool,
        errorMessage: String?,
        loadingMessage: String = "加载中...",
        retryAction: (() -> Void)? = nil,
        isLoginRequired: Bool = false,
        loginAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.isEmpty = isEmpty
        self.errorMessage = errorMessage
        self.loadingMessage = loadingMessage
        self.retryAction = retryAction
        self.isLoginRequired = isLoginRequired
        self.loginAction = loginAction
        self.content = content
    }

    var body: some View {
        Group {
            if isLoading && isEmpty {
                ProgressView(loadingMessage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.Colors.pageBackground)
            } else if let error = errorMessage, isEmpty {
                ErrorStateView(
                    message: error,
                    retryAction: isLoginRequired ? nil : retryAction,
                    primaryButtonTitle: isLoginRequired ? "去登录" : nil,
                    primaryButtonAction: isLoginRequired ? loginAction : nil
                )
                .background(AppTheme.Colors.pageBackground)
            } else {
                content()
            }
        }
    }
}
