//
//  AppTheme.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

/// Centralized design tokens for the NGA app. Single source of truth for colors and styling.
/// Use these throughout the app so theme switching can be added later by changing values here.
enum AppTheme {
    enum Colors {
        /// Default page background (yellowish cream). Apply to all screens. Change here for theme switching.
        static let pageBackground = Color(red: 0.95, green: 0.91, blue: 0.82)

        /// Content surfaces: cards, list rows, panels (white for contrast on pageBackground)
        static var contentBackground = pageBackground

        /// Primary background - cream/beige (alias, prefer pageBackground)
        static let background = Color(red: 0.96, green: 0.94, blue: 0.89)

        /// Home screen background (same as pageBackground for consistency)
        static let homeBackground = pageBackground

        /// Tab bar / accent tint (orange for NGA)
        static let accent = Color.orange

        /// Selected category pill
        static let categorySelected = Color(red: 0.2, green: 0.25, blue: 0.35)

        /// Card/panel backgrounds (same as contentBackground)
        static let cardBackground = Color.white

        /// Check-in banner gradient colors
        static let bannerStart = Color(red: 0.3, green: 0.35, blue: 0.45)
        static let bannerEnd = Color(red: 0.25, green: 0.3, blue: 0.4)

        /// Decorative gradient for banners
        static let bannerDecorStart = Color(red: 1.0, green: 0.96, blue: 0.88)
        static let bannerDecorEnd = Color(red: 0.98, green: 0.94, blue: 0.85)

        /// Forum card avatar gradient colors (for consistent random selection)
        static let avatarColors: [Color] = [
            .blue, .purple, .pink, .red, .orange, .yellow, .green, .teal, .indigo
        ]
        
        /// Thread list - pinned/important thread color
        static let pinnedThread = Color.red
        
        /// Secondary text color
        static let secondaryText = Color.secondary
        
        /// Primary text color
        static let primaryText = Color.primary
    }

    enum Layout {
        static let cardCornerRadius: CGFloat = 12
        static let cardShadowRadius: CGFloat = 3
        static let cardShadowOpacity: Double = 0.06

        static let forumGridColumns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        /// Standard padding for most UI elements (16pt)
        static let standardPadding: CGFloat = 16
        
        /// Compact padding for tight spaces (8pt)
        static let compactPadding: CGFloat = 8
        
        /// Small spacing between elements (4pt)
        static let smallSpacing: CGFloat = 4
        
        /// Medium spacing (12pt)
        static let mediumSpacing: CGFloat = 12
        
        /// Standard spacing between elements (16pt)
        static let standardSpacing: CGFloat = 16
        
        /// Avatar size for post authors (48pt)
        static let avatarSize: CGFloat = 48
        
        /// Avatar size for thread lists (32pt)
        static let threadAvatarSize: CGFloat = 32
    }
    
    enum FontSize {
        /// Large title (20pt)
        static let threadDetailTitle: CGFloat = 20
        
        /// Title 3 / icon size (20pt)
        static let title3: CGFloat = 20
        
        /// Body text (16pt)
        static let body: CGFloat = 16
        
        /// Small body (15pt)
        static let smallBody: CGFloat = 15
        
        /// Caption text (13pt)
        static let caption: CGFloat = 13
        
        /// Small caption (12pt)
        static let smallCaption: CGFloat = 12
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies the app's default page background. Use on all main screens so theme switching works globally.
    func ngaPageBackground() -> some View {
        background(AppTheme.Colors.pageBackground.ignoresSafeArea())
    }
}
