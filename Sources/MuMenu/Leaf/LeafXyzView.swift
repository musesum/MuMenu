//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

public struct LeafXyzView: View {

    @ObservedObject var leafVm: LeafXyzVm

    public init(leafVm: LeafXyzVm) {
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
                        LeafThumbSlideView(leafVm, .runXY)
                        #else
                        LeafThumbSlideView(leafVm, .runXY, leafVm.ticks())
                        #endif
                    }
                    LeafBezelView(leafVm, .runZ) {
                        LeafThumbSlideView(leafVm, .runZ)
                    }
                }
            }
        }
    }
}


