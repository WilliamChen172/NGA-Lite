//
//  ThreadListView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

struct ThreadListView: View {
    let forum: Forum
    @StateObject private var viewModel: ThreadListViewModel
    @State private var selectedTab = 0
    @EnvironmentObject var authService: AuthService
    @Environment(\.currentTabIndex) private var currentTabIndex
    
    init(forum: Forum, forumService: any ForumServiceProtocol = ForumService.shared) {
        self.forum = forum
        _viewModel = StateObject(wrappedValue: ThreadListViewModel(forumService: forumService))
    }

    var body: some View {
        VStack(spacing: 0) {
                // Tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        TabButton(title: "全部", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        TabButton(title: "置顶", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        TabButton(title: "热帖", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                        TabButton(title: "精华", isSelected: selectedTab == 3) {
                            selectedTab = 3
                        }
                        TabButton(title: "子版块", isSelected: selectedTab == 4) {
                            selectedTab = 4
                        }
                    }
                    .padding(.horizontal, AppTheme.Layout.standardPadding)
                    .padding(.vertical, AppTheme.Layout.mediumSpacing)
                }
                .background(AppTheme.Colors.contentBackground)
                
                Divider()
                
                // Thread list
                LoadableView(
                    isLoading: viewModel.isLoading,
                    isEmpty: viewModel.threads.isEmpty,
                    errorMessage: viewModel.errorMessage,
                    retryAction: { Task { await viewModel.loadThreads(forumId: forum.fid) } },
                    isLoginRequired: viewModel.isLoginRequired,
                    loginAction: { authService.requestLogin(fromTab: currentTabIndex) }
                ) {
                    List {
                        ForEach(viewModel.threads) { thread in
                            NavigationLink(value: thread) {
                                ThreadRowView(thread: thread)
                            }
                            .listRowBackground(AppTheme.Colors.contentBackground)
                            .listRowInsets(EdgeInsets(
                                top: AppTheme.Layout.mediumSpacing,
                                leading: AppTheme.Layout.standardPadding,
                                bottom: AppTheme.Layout.mediumSpacing,
                                trailing: AppTheme.Layout.standardPadding
                            ))
                            .listRowSeparator(.visible)
                            .onAppear {
                                if thread.id == viewModel.threads.last?.id {
                                    Task { await viewModel.loadNextPage() }
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(AppTheme.Colors.contentBackground)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
        }
        .navigationTitle(forum.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(ThreadSortOrder.allCases, id: \.rawValue) { order in
                        Button {
                            Task { await viewModel.switchSortOrder(order) }
                        } label: {
                            HStack {
                                Text(order.displayName)
                                if order == viewModel.sortOrder {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label("排序", systemImage: "arrow.up.arrow.down.circle")
                }
            }
        }
        .task {
            await viewModel.loadThreads(forumId: forum.fid)
        }
        .refreshable {
            await viewModel.loadThreads(forumId: forum.fid)
        }
        .navigationDestination(for: ForumThread.self) { thread in
            ThreadDetailView(thread: thread)
        }
        .ngaPageBackground()
    }
}

#Preview("Thread List") {
    NavigationStack {
        ThreadListView(
            forum: Forum(
                fid: 1,
                name: "PC 软硬件",
                name2: nil,
                description: nil,
                parent: nil,
                subForums: nil
            ),
            forumService: MockForumService()
        )
        .environmentObject(AuthService.shared)
    }
}
