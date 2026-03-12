//
//  ProfileView.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showNativeLogin = false
    @State private var showWebViewLogin = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.homeBackground
                .ignoresSafeArea()
            
            List {
                if authService.isAuthenticated {
                    // User is logged in - show profile
                    userProfileSection
                    userActionsSection
                    logoutSection
                } else {
                    // User is not logged in - show WebView login prompt
                    loginPromptSection
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNativeLogin) {
            NavigationStack {
                NativeLoginView(authService: authService)
            }
        }
        .sheet(isPresented: $showWebViewLogin) {
            WebViewLoginView(authService: authService) {}
        }
    }
    
    private var loginPromptSection: some View {
        Section {
            VStack(spacing: AppTheme.Layout.mediumSpacing) {
                Image(systemName: "person.circle")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Colors.accent)
                    .padding(.top, AppTheme.Layout.standardPadding)
                
                Text("登录后查看更多内容")
                    .font(.system(size: AppTheme.FontSize.body))
                    .foregroundColor(.secondary)

                Button {
                    showNativeLogin = true
                } label: {
                    Text("客户端登录")
                        .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.accent)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button {
                    showWebViewLogin = true
                } label: {
                    Text("网页登录（支持验证码）")
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, AppTheme.Layout.standardPadding)
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        }
    }
    
    private var userProfileSection: some View {
        Section {
            if let user = authService.currentUser {
                HStack(spacing: AppTheme.Layout.mediumSpacing) {
                    // Avatar
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.system(size: AppTheme.FontSize.body, weight: .semibold))
                        
                        if let username = user.username {
                            Text("@\(username)")
                                .font(.system(size: AppTheme.FontSize.caption))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Layout.compactPadding)
            }
        }
    }
    
    private var userActionsSection: some View {
        Section {
            NavigationLink {
                Text("我的帖子")
                    .navigationTitle("我的帖子")
            } label: {
                Label("我的帖子", systemImage: "doc.text")
            }
            
            NavigationLink {
                Text("收藏")
                    .navigationTitle("收藏")
            } label: {
                Label("收藏", systemImage: "star")
            }
            
            NavigationLink {
                Text("历史记录")
                    .navigationTitle("历史记录")
            } label: {
                Label("历史记录", systemImage: "clock")
            }
            
            NavigationLink {
                SettingsView()
            } label: {
                Label("设置", systemImage: "gear")
            }
        }
    }
    
    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                authService.logout()
            } label: {
                HStack {
                    Spacer()
                    Text("退出登录")
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthService.shared)
    }
}
