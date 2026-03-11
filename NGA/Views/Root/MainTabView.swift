//
//  MainTabView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView(selection: $authService.selectedTab) {
            NavigationStack {
                HomeView()
                    .environment(\.currentTabIndex, Constants.TabIndex.home)
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(Constants.TabIndex.home)
            
            NavigationStack {
                ForumListView()
                    .environment(\.currentTabIndex, Constants.TabIndex.forum)
            }
            .tabItem {
                Label("社区", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(Constants.TabIndex.forum)
            
            NavigationStack {
                NotificationsView()
                    .environment(\.currentTabIndex, Constants.TabIndex.notifications)
            }
            .tabItem {
                Label("消息", systemImage: "bell.fill")
            }
            .tag(Constants.TabIndex.notifications)

            NavigationStack {
                ProfileView()
                    .environment(\.currentTabIndex, Constants.TabIndex.profile)
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(Constants.TabIndex.profile)
        }
        .tint(AppTheme.Colors.accent)
        .ngaPageBackground()
        .onChange(of: authService.selectedTab) { oldValue, newValue in
            if oldValue == Constants.TabIndex.profile && newValue != Constants.TabIndex.profile, !authService.isAuthenticated {
                authService.pendingAction = nil
            }
        }
        .alert("登录已过期", isPresented: Binding(
            get: { authService.needsReauthAlert },
            set: { authService.needsReauthAlert = $0 }
        )) {
            Button("确定", role: .cancel) {
                authService.needsReauthAlert = false
            }
        } message: {
            Text("请重新登录")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
}
