//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

struct LeafXyzView: View {

    @ObservedObject var leafVm: LeafXyzVm

    var size: CGSize { leafVm.panelVm.outerPanel }

    public var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 0) {

                HStack(alignment: .center, spacing: 4) {
                    Spacer()
                    LeafBezelView(leafVm, .runX) {
                        LeafThumbSlideView(leafVm, .runX)
                    }
                    .padding(EdgeInsets(top: 2, leading: 2, bottom: -2, trailing: 0))
                    LeafHeaderDeltaView(leafVm)
                        .padding(EdgeInsets(top: 2, leading: 0, bottom: -2, trailing: 4))
                }

                HStack(alignment: .center, spacing: 4) {

                    LeafBezelView(leafVm, .runY) {
                        LeafThumbSlideView(leafVm, .runY)
                    }
                    LeafBezelView(leafVm, .runXYZ)  {
                        ZStack {
                            LeafTicksView(leafVm.ticks())
                            LeafThumbSlideView(leafVm, .runXYZ)
                        }
                    }
                    LeafBezelView(leafVm, .runZ) {
                        LeafThumbSlideView(leafVm, .runZ)
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}


