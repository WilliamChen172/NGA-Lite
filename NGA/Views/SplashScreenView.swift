//
//  SplashScreenView.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            AppTheme.Colors.homeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo/Icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.accent.opacity(0.8),
                                AppTheme.Colors.accent.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay {
                        Text("NGA")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // App Name
                Text("NGA论坛")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                    .opacity(opacity)
                
                // Tagline
                Text("全新升级 · 畅享交流")
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.6))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
            
            withAnimation(.easeIn(duration: 0.5).delay(0.2)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
