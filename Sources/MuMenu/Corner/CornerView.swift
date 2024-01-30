// created by musesum 10/29/21.

import SwiftUI

/// Capture SwiftUI drag gestures
struct CornerView: View {

    @ObservedObject var cornerVm: CornerVm

    var body: some View {

        GeometryReader() { geo  in
            // parked icon
            if let logoNodeVm = cornerVm.logoNodeVm {
                
                CursorView(logoNodeVm, Layout.diameter)
                   
                    .onAppear { cornerVm.updateRootIcon(geo.frame(in: .global)) }
                    #if os(visionOS)
                    .onChange(of: geo.frame(in: .global)) { old, now in cornerVm.updateRootIcon(now) }
                    #else
                    .onChange(of: geo.frame(in: .global)) { cornerVm.updateRootIcon($0) }
                    #endif

                    .padding(Layout.padding2)
                    .position(cornerVm.parkIconXY)
                    .offset(cornerVm.rootVm?.rootOffset ?? .zero)
            }

            // drag icon, follows touch
            if let ringNodeVm = cornerVm.ringNodeVm {

                CursorView(ringNodeVm, Layout.diameter2)
                    .position(cornerVm.ringIconXY)
                    .animation(Layout.animateFast, value: cornerVm.ringIconXY)
                    .offset(cornerVm.dragNodeΔ) // .zero
            }
        }
        //???.animation(Layout.animateFast, value: cornerVm.parkIconAlpha)
    }
}
