//
//  HomeView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ZStack {
            AppTheme.Colors.homeBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header with profile
                    header
                    
                    // Banner section
                    bannerSection
                    
                    // Hot threads section
                    hotThreadsSection
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            Text("NGA论坛")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var bannerSection: some View {
        VStack(spacing: 12) {
            // Top banner
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.Colors.bannerDecorStart, AppTheme.Colors.bannerDecorEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 160)
                .overlay {
                    Text("NGA客户端\n全新升级")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            
            // Daily check-in banner
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.Colors.bannerStart, AppTheme.Colors.bannerEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 100)
                .overlay(alignment: .leading) {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding(.leading, 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NGA每日签到")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("累计签到 0 天")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                }
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            
            // Quick action buttons
            HStack(spacing: 12) {
                quickActionButton(icon: "calendar", title: "任务")
                quickActionButton(icon: "book", title: "档目")
                quickActionButton(icon: "gamecontroller", title: "评分")
                quickActionButton(icon: "trophy", title: "赛事")
                quickActionButton(icon: "heart", title: "关注")
                quickActionButton(icon: "mic", title: "聊天室")
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private func quickActionButton(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.black.opacity(0.7))
            Text(title)
                .font(.caption)
                .foregroundColor(.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var hotThreadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("论坛热帖")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("换一换")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.5))
                        Image(systemName: "dice")
                            .foregroundColor(.black.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Placeholder for hot threads
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 200, height: 120)
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                            .overlay {
                                Text("热门帖子 \(index + 1)")
                                    .foregroundColor(.black.opacity(0.5))
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthService.shared)
    }
}
