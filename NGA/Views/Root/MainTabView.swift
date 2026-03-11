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
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            
            NavigationStack {
                ForumListView()
            }
            .tabItem {
                Label("社区", systemImage: "bubble.left.and.bubble.right.fill")
            }
            
            NavigationStack {
                NotificationsView()
            }
            .tabItem {
                Label("消息", systemImage: "bell.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
        }
        .tint(AppTheme.Colors.accent)
        .ngaPageBackground()
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
}
