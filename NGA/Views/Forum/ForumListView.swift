//
//  ForumListView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

private struct IdentifiedForum: Identifiable {
    let id: String
    let forum: Forum
}

struct ForumListView: View {
    @StateObject private var viewModel: ForumListViewModel
    @EnvironmentObject var authService: AuthService
    @State private var expandedCategoryIds: Set<Int> = []  // empty = all collapsed by default
    
    init(forumService: any ForumServiceProtocol = ForumService.shared) {
        _viewModel = StateObject(wrappedValue: ForumListViewModel(forumService: forumService))
    }
    
    var body: some View {
        LoadableView(
            isLoading: viewModel.isLoading,
            isEmpty: viewModel.forums.isEmpty,
            errorMessage: viewModel.errorMessage,
            retryAction: { Task { await viewModel.loadForums() } }
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.categories) { category in
                        forumCategorySection(category)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(AppTheme.Colors.pageBackground)
        }
        .refreshable {
            await viewModel.loadForums()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("论坛")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .task {
            await viewModel.loadForums()
        }
        .navigationDestination(for: Forum.self) { forum in
            ThreadListView(forum: forum)
        }
        .ngaPageBackground()
    }
    
    /// Wrapper so same forum in different groups gets unique id (avoids ForEach recycling wrong cards)
    private func forumsWithUniqueIds(group: ForumGroupDisplay) -> [IdentifiedForum] {
        group.forums.enumerated().map { idx, forum in
            IdentifiedForum(id: "\(group.id)-\(forum.fid)-\(idx)", forum: forum)
        }
    }

    private func forumCategorySection(_ category: ForumCategoryDisplay) -> some View {
        let isExpanded = expandedCategoryIds.contains(category.id)
        return VStack(alignment: .leading, spacing: 12) {
            // Section header - card style with theme background
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedCategoryIds.remove(category.id)
                    } else {
                        expandedCategoryIds.insert(category.id)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if !category.name.isEmpty {
                        Text(category.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.Colors.contentBackground)
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(category.groups) { group in
                        if let groupName = group.name, !groupName.isEmpty {
                            Text(groupName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                        LazyVGrid(columns: AppTheme.Layout.forumGridColumns, spacing: 16) {
                            ForEach(forumsWithUniqueIds(group: group)) { item in
                                NavigationLink(value: item.forum) {
                                    ForumCard(forum: item.forum)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForumListView(forumService: MockForumService())
            .environmentObject(AuthService.shared)
    }
}
