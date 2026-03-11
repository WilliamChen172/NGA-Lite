//
//  ReplyView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

struct ReplyView: View {
    @ObservedObject var viewModel: ThreadDetailViewModel
    let onDismiss: () -> Void

    @State private var content = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.homeBackground
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("回复")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发送") {
                        postReply()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPosting)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "发送失败")
            }
        }
    }

    private func postReply() {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        Task {
            do {
                try await viewModel.createReply(content: text)
                onDismiss()
            } catch {
                showError = true
            }
        }
    }
}
