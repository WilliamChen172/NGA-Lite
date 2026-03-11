//
//  TabButton.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: AppTheme.FontSize.body, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Rectangle()
                    .fill(isSelected ? AppTheme.Colors.accent : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Selected") {
    TabButton(title: "全部", isSelected: true) {}
}

#Preview("Unselected") {
    TabButton(title: "置顶", isSelected: false) {}
}
