// created by musesum on 10/7/21.

import SwiftUI
#if os(visionOS)
struct BranchPanelView: View {

    var body: some View {

        GeometryReader { geo in
            Rectangle()
                .opacity(0)
                .cornerRadius(Menu.cornerRadius)
        }
        .glassBackgroundEffect(in: .rect(cornerRadius: Menu.cornerRadius) )
    }
}
#else
struct BranchPanelView: View {

    var body: some View {

        if #available(iOS 26.0, *) {
            GeometryReader { geo in
                Rectangle()
                    .opacity(0)
            }
            .glassEffect(.clear, in: .rect(cornerRadius: Menu.cornerRadius))
            .cornerRadius(Menu.cornerRadius)

        } else {
            GeometryReader { geo in
                Rectangle()
                    .background(.thickMaterial)
                    .opacity(0.5)
                    .cornerRadius(Menu.cornerRadius)
            }
        }


    }
}
#endif

