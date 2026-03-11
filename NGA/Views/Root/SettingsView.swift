//
//  SettingsView.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoPlayVideos") private var autoPlayVideos = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("fontSize") private var fontSize = "medium"
    
    var body: some View {
        ZStack {
            AppTheme.Colors.homeBackground
                .ignoresSafeArea()
            
            List {
                Section("通用") {
                    Toggle("自动播放视频", isOn: $autoPlayVideos)
                    Toggle("接收通知", isOn: $enableNotifications)
                    Toggle("深色模式", isOn: $darkModeEnabled)
                    
                    Picker("字体大小", selection: $fontSize) {
                        Text("小").tag("small")
                        Text("中").tag("medium")
                        Text("大").tag("large")
                    }
                }
                
                Section("内容设置") {
                NavigationLink {
                    Text("屏蔽列表")
                        .navigationTitle("屏蔽列表")
                } label: {
                    Label("屏蔽列表", systemImage: "hand.raised")
                }
                
                NavigationLink {
                    Text("内容过滤")
                        .navigationTitle("内容过滤")
                } label: {
                    Label("内容过滤", systemImage: "eye.slash")
                }
            }
            
            Section("账号与隐私") {
                NavigationLink {
                    Text("账号设置")
                        .navigationTitle("账号设置")
                } label: {
                    Label("账号设置", systemImage: "person.circle")
                }
                
                NavigationLink {
                    Text("隐私设置")
                        .navigationTitle("隐私设置")
                } label: {
                    Label("隐私设置", systemImage: "lock.shield")
                }
            }
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink {
                    Text("关于NGA")
                        .navigationTitle("关于NGA")
                } label: {
                    Label("关于NGA", systemImage: "info.circle")
                }
                
                NavigationLink {
                    Text("帮助与反馈")
                        .navigationTitle("帮助与反馈")
                } label: {
                    Label("帮助与反馈", systemImage: "questionmark.circle")
                }
            }
            
            Section("缓存管理") {
                Button {
                    // Clear cache action
                } label: {
                    HStack {
                        Text("清除缓存")
                        Spacer()
                        Text("0 MB")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
    .navigationTitle("设置")
    .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
