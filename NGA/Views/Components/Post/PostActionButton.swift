//
//  PostActionButton.swift
//  NGA
//
//  Created by William Chen on 3/11/26.
//

import SwiftUI

struct PostActionButton: View {
    let icon: String
    
    var body: some View {
        Button {
            // Action - not implemented in MVP
        } label: {
            Image(systemName: icon)
                .font(.system(size: AppTheme.FontSize.title3))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    HStack(spacing: 32) {
        PostActionButton(icon: "gift")
        PostActionButton(icon: "hand.thumbsup")
        PostActionButton(icon: "hand.thumbsdown")
        PostActionButton(icon: "bubble.left")
        PostActionButton(icon: "plus")
    }
    .padding()
}
