// created by musesum 10/29/21.

import SwiftUI

/// Capture SwiftUI drag gestures
struct CornerView: View {

    var cornerVm: CornerVm
    var opacity: CGFloat { cornerVm.touchState.touching ? 1 : 0.25 }

    var body: some View {

        GeometryReader() { geo  in
            // parked icon
            if let logoNodeVm = cornerVm.logoNodeVm {
                
                CursorView(logoNodeVm, Menu.diameter)
                   
                    .onAppear { cornerVm.updateRootIcon(geo.frame(in: .global)) }
                    .onChange(of: geo.frame(in: .global)) { cornerVm.updateRootIcon($1) }

                    .padding(Menu.padding2)
                    .position(cornerVm.parkIconXY)
            }

            // drag icon, follows touch
            if let ringNodeVm = cornerVm.ringNodeVm {

                CursorView(ringNodeVm, Menu.diameter2)
                    .position(cornerVm.ringIconXY)
                    .offset(cornerVm.dragNodeΔ()) // .kludge
                    .animation(Animate(0.25), value: cornerVm.ringIconXY)
                    .opacity(opacity)
                    .animation(Animate(0.50), value: opacity)
            }
        }
    }
}
