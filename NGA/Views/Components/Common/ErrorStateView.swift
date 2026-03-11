//
//  ErrorStateView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

/// Error/empty state view compatible with iOS 16 (ContentUnavailableView is iOS 17+).
struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    let primaryButtonTitle: String?
    let primaryButtonAction: (() -> Void)?

    init(title: String = "加载失败", message: String, retryAction: (() -> Void)? = nil, primaryButtonTitle: String? = nil, primaryButtonAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryButtonAction = primaryButtonAction
    }

    private var isLoginRequired: Bool { primaryButtonTitle == "去登录" }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isLoginRequired ? "lock.fill" : "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(isLoginRequired ? "需要登录" : title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let title = primaryButtonTitle, let action = primaryButtonAction {
                Button(title, action: action)
            } else if let retryAction {
                Button("重试", action: retryAction)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
