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
    @EnvironmentObject var authService: AuthService
    @Environment(\.currentTabIndex) private var currentTabIndex
    
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
            loginAction: { authService.requestLogin(fromTab: currentTabIndex) }
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
                        ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                            PostDetailView(
                                post: post,
                                authorInfo: viewModel.authorInfo(for: post),
                                posts: viewModel.posts,
                                rowIndex: index,
                                fetchPostByPid: { pid in try await viewModel.fetchPostByPid(pid: pid) },
                                onVoteUp: {
                                    if authService.requireAuthFor(.votePost(postId: post.id, tid: post.tid, pid: post.pid, upvote: true)) {
                                        Task { await viewModel.votePost(postId: post.id, tid: post.tid, pid: post.pid, upvote: true) }
                                    } else {
                                        authService.requestLogin(fromTab: currentTabIndex)
                                    }
                                },
                                onVoteDown: {
                                    if authService.requireAuthFor(.votePost(postId: post.id, tid: post.tid, pid: post.pid, upvote: false)) {
                                        Task { await viewModel.votePost(postId: post.id, tid: post.tid, pid: post.pid, upvote: false) }
                                    } else {
                                        authService.requestLogin(fromTab: currentTabIndex)
                                    }
                                }
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
                    if authService.requireAuthFor(.replyToThread(threadId: thread.tid)) {
                        showReplySheet = true
                    } else {
                        authService.requestLogin(fromTab: currentTabIndex)
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
        .onChange(of: authService.postLoginIntent) { _, intent in
            guard let intent else { return }
            switch intent {
            case .replyToThread(let threadId) where threadId == thread.tid:
                showReplySheet = true
                authService.clearPostLoginIntent()
            case .votePost(let postId, let tid, let pid, let upvote) where tid == thread.tid:
                Task { await viewModel.votePost(postId: postId, tid: tid, pid: pid, upvote: upvote) }
                authService.clearPostLoginIntent()
            default:
                break
            }
        }
        .onAppear {
            guard let intent = authService.postLoginIntent else { return }
            switch intent {
            case .replyToThread(let threadId) where threadId == thread.tid:
                showReplySheet = true
                authService.clearPostLoginIntent()
            case .votePost(let postId, let tid, let pid, let upvote) where tid == thread.tid:
                Task { await viewModel.votePost(postId: postId, tid: tid, pid: pid, upvote: upvote) }
                authService.clearPostLoginIntent()
            default:
                break
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
        .environmentObject(AuthService.shared)
        .environment(\.currentTabIndex, Constants.TabIndex.forum)
    }
}
