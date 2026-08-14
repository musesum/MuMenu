//  created by musesum on 7/11/26.

import SwiftUI
import MuFlo

/// XYZW layout = LeafXyzView plus a bottom W row.
/// The W bezel is horizontally aligned with the X bezel by reserving the
/// same leading header width with an invisible header twin — alignment holds
/// even when the live header text changes width.
/// The pad hosts two thumbs (LeafThumbPadView): filled = active pair
/// (XY or WZ), dotted = inactive pair; tapping the dotted thumb swaps.
public struct LeafXyzwView: View {

    @ObservedObject var leafVm: LeafXyzwVm

    public init(leafVm: LeafXyzwVm) {
        self.leafVm = leafVm
    }

    public var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 0) {

                HStack(alignment: .center, spacing: 4) {

                    LeafHeaderDeltaView(leafVm)
                        #if os(watchOS)
                        .padding(EdgeInsets(top: 2, leading: 2, bottom: 0, trailing: 0))
                        #else
                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 0))
                        #endif
                    LeafBezelView(leafVm, .runX) {
                        LeafThumbSlideView(leafVm, .runX)
                    }
                    Spacer()
                }

                HStack(alignment: .center, spacing: 4) {

                    LeafBezelView(leafVm, .runY) {
                        LeafThumbSlideView(leafVm, .runY)
                    }
                    LeafBezelView(leafVm, .runXY)  {
                        #if os(watchOS)
                        LeafThumbPadView(leafVm)
                        #else
                        LeafThumbPadView(leafVm, leafVm.ticks())
                        #endif
                    }
                    LeafBezelView(leafVm, .runZ) {
                        LeafThumbSlideView(leafVm, .runZ)
                    }
                }

                // w on the bottom, aligned horizontally with the x slider:
                // the invisible header twin reserves the identical leading
                // width the x row's live header occupies
                HStack(alignment: .center, spacing: 4) {

                    LeafHeaderDeltaView(leafVm)
                        #if os(watchOS)
                        .padding(EdgeInsets(top: 2, leading: 2, bottom: 0, trailing: 0))
                        #else
                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 0))
                        #endif
                        .opacity(0)
                        .allowsHitTesting(false)
                    LeafBezelView(leafVm, .runW) {
                        LeafThumbSlideView(leafVm, .runW)
                    }
                    Spacer()
                }
            }
        }
    }
}
