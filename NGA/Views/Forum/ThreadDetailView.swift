//
//  ThreadDetailView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

struct ThreadDetailView: View {
    let thread: ForumThread
    @StateObject private var viewModel: ThreadDetailViewModel
    @State private var showReplySheet = false
    @State private var showLoginSheet = false
    @EnvironmentObject var authService: AuthService
    
    init(thread: ForumThread, forumService: any ForumServiceProtocol = ForumService.shared) {
        self.thread = thread
        _viewModel = StateObject(wrappedValue: ThreadDetailViewModel(forumService: forumService))
    }

    var body: some View {
        LoadableView(
            isLoading: viewModel.isLoading,
            isEmpty: viewModel.posts.isEmpty,
            errorMessage: viewModel.errorMessage,
            retryAction: { Task { await viewModel.loadThread(threadId: thread.tid) } },
            isLoginRequired: viewModel.isLoginRequired,
            loginAction: { showLoginSheet = true }
        ) {
            ScrollView {
                VStack(spacing: 0) {
                    // Thread title header
                    VStack(alignment: .leading, spacing: AppTheme.Layout.mediumSpacing) {
                        Text(thread.subject)
                            .font(.system(size: AppTheme.FontSize.threadDetailTitle, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, AppTheme.Layout.standardPadding)
                    .padding(.vertical, AppTheme.Layout.standardPadding)
                    .background(AppTheme.Colors.contentBackground)
                    
                    Divider()
                    
                    // Posts list
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.posts) { post in
                            PostDetailView(
                                post: post,
                                onVoteUp: { Task { await viewModel.votePost(postId: post.id, tid: post.tid, pid: post.pid, upvote: true) } },
                                onVoteDown: { Task { await viewModel.votePost(postId: post.id, tid: post.tid, pid: post.pid, upvote: false) } }
                            )
                            
                            Divider()
                                .padding(.leading, AppTheme.Layout.standardPadding)
                            
                            // Trigger pagination
                            Color.clear
                                .frame(height: 1)
                                .onAppear {
                                    if post.id == viewModel.posts.last?.id {
                                        Task { await viewModel.loadNextPage() }
                                    }
                                }
                        }
                        
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                }
            }
            .background(AppTheme.Colors.pageBackground)
        }
        .navigationTitle("主题")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if authService.isAuthenticated {
                        showReplySheet = true
                    } else {
                        showLoginSheet = true
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("回复")
            }
        }
        .task {
            await viewModel.loadThread(threadId: thread.tid)
        }
        .refreshable {
            await viewModel.loadThread(threadId: thread.tid)
        }
        .sheet(isPresented: $showReplySheet) {
            ReplyView(viewModel: viewModel) {
                showReplySheet = false
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            NavigationStack {
                LoginView(authService: authService)
            }
        }
        .ngaPageBackground()
    }
}

#Preview("Thread Detail") {
    NavigationStack {
        ThreadDetailView(
            thread: ForumThread(
                tid: 1,
                fid: 1,
                subject: "9850x3d+5070ti，fps+追剧五五开，选2k还是4k?",
                authorId: 1,
                author: "永结桐心",
                postDate: nil,
                replyCount: 12,
                lastPost: nil
            ),
            forumService: MockForumService()
        )
    }
}
