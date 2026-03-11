//
//  NGAApp.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

@main
struct NGAApp: App {
    @StateObject private var authService = AuthService.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(authService)
                    .task {
                        await authService.restoreSession()
                    }
                
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Hide splash after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
