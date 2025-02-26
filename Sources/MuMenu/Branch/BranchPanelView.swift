// created by musesum on 10/7/21.

import SwiftUI

struct BranchPanelView: View {
    
    let spotlight: Bool

    var body: some View {
        GeometryReader { geo in
            Rectangle()
            #if os(visionOS)
                .background(.clear)
                .opacity(0.38)
            #else
                .background(.ultraThinMaterial)
                .opacity(0.62)
            #endif
                .cornerRadius(Layout.cornerRadius)
                .shadow(color: .black, radius: 3)
        }
    }
}
