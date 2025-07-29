// created by musesum on 10/7/21.

import SwiftUI
#if os(visionOS)
struct BranchPanelView: View {

    @EnvironmentObject var glassState: GlassState

    var body: some View {
        if glassState.glass {
            GeometryReader { geo in
                Rectangle()
                    .opacity(0)
                    .cornerRadius(Menu.cornerRadius)
            }
            .glassBackgroundEffect(in: .rect(cornerRadius: Menu.cornerRadius) )

        } else {
            Rectangle()
                .background(.thickMaterial)
                .opacity(0.35)
                .cornerRadius(Menu.cornerRadius)
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

