// Created by warren on 10/7/21.

import SwiftUI

struct MuBranchPanelView: View {
    
    let spotlight: Bool
    var strokeColor: Color { spotlight ? .white : .clear }
    var lineWidth: CGFloat { spotlight ? 1 : 1 }

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .background(.ultraThinMaterial)
                .cornerRadius(Layout.cornerRadius)
                .overlay(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(strokeColor, lineWidth: lineWidth))
                .opacity(0.66)
        }
    }
}
