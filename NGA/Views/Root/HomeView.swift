//
//  HomeView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab = 1  // 默认推荐

    var body: some View {
        ZStack {
            AppTheme.Colors.homeBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部 Tab：关注 | 推荐 | 热帖
                Picker("首页", selection: $selectedTab) {
                    Text("关注").tag(0)
                    Text("推荐").tag(1)
                    Text("热帖").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Layout.standardPadding)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.homeBackground)

                TabView(selection: $selectedTab) {
                    homeTabContent(tab: 0).tag(0)
                    homeTabContent(tab: 1).tag(1)
                    homeTabContent(tab: 2).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
        .navigationDestination(for: ForumThread.self) { thread in
            ThreadDetailView(thread: thread)
        }
    }

    private func homeTabContent(tab: Int) -> some View {
        LoadableView(
            isLoading: viewModel.isLoading,
            isEmpty: tab != 0 && viewModel.threads(for: tab).isEmpty && !viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            retryAction: { Task { await viewModel.loadData() } }
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    if tab == 0 {
                        Text("关注内容敬请期待")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        let threads = viewModel.threads(for: tab)
                        if !threads.isEmpty {
                            LazyVGrid(columns: AppTheme.Layout.forumGridColumns, spacing: 12) {
                                ForEach(threads) { card in
                                    NavigationLink(value: card.thread) {
                                        HomeRecmTopicCardView(card: card)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, AppTheme.Layout.standardPadding)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthService.shared)
    }
}
