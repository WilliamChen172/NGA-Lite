//
//  NotificationsView.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct NotificationsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            AppTheme.Colors.homeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab selector
                Picker("通知类型", selection: $selectedTab) {
                    Text("系统").tag(0)
                    Text("回复").tag(1)
                    Text("@我").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(AppTheme.Layout.standardPadding)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    notificationList(type: "系统")
                        .tag(0)
                    
                    notificationList(type: "回复")
                        .tag(1)
                    
                    notificationList(type: "@我")
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle("消息")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func notificationList(type: String) -> some View {
        List {
            ForEach(0..<5) { index in
                NotificationRow(
                    title: "\(type)通知 \(index + 1)",
                    message: "这是一条\(type)通知的示例内容，用于展示通知列表的布局效果。",
                    time: "2小时前",
                    isUnread: index < 2
                )
            }
        }
        .listStyle(.plain)
    }
}

struct NotificationRow: View {
    let title: String
    let message: String
    let time: String
    let isUnread: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Layout.mediumSpacing) {
            // Notification icon
            Circle()
                .fill(isUnread ? AppTheme.Colors.accent : Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "bell.fill")
                        .font(.system(size: AppTheme.FontSize.body))
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: AppTheme.FontSize.body, weight: isUnread ? .semibold : .regular))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.system(size: AppTheme.FontSize.caption))
                        .foregroundColor(.secondary)
                }
                
                Text(message)
                    .font(.system(size: AppTheme.FontSize.caption))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, AppTheme.Layout.compactPadding)
        .background(isUnread ? Color.accentColor.opacity(0.05) : Color.clear)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
