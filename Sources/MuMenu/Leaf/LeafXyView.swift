//  created by musesum on 5/10/22.

import SwiftUI

public struct LeafXyView: View {

    @ObservedObject var leafVm: LeafXyVm

    public init(leafVm: LeafXyVm) {
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
                        // Ticks dots are removed on watch for clarity.
                        #if os(watchOS)
                        LeafThumbSlideView(leafVm, .runXY)
                        #else
                        LeafThumbSlideView(leafVm, .runXY, leafVm.ticks())
                        #endif
                    }
                }
            }
        }
    }
}


