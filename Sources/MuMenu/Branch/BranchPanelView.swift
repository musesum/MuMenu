// created by musesum on 10/7/21.

import SwiftUI
#if os(visionOS)
struct BranchPanelView: View {

    var body: some View {

        GeometryReader { geo in
            if false {
                Circle()
                    .fill(.green)
                    .opacity(0.38)
                    //.background(.blue)
                    .glassBackgroundEffect()
                    //.cornerRadius(Menu.cornerRadius)
            } else {
                Rectangle()
                    .background(.ultraThinMaterial)
                    .opacity(0.25)
                    .cornerRadius(Menu.cornerRadius)
            }
        }


    }
}
#else
struct BranchPanelView: View {

    @EnvironmentObject var glassState: GlassState

    var body: some View {

        if #available(iOS 26.0, *), glassState.glass {
            GeometryReader { geo in
                Rectangle()
                    .background(.black)
                    .opacity(0.2)
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
