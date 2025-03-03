//  created by musesum on 5/10/22.

import SwiftUI

public struct LeafXyView: View {

    @ObservedObject var leafVm: LeafXyVm

    var size: CGSize { leafVm.panelVm.outerPanel }

    public var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 0) {

                HStack(alignment: .center, spacing: 4) {

                    LeafHeaderDeltaView(leafVm)
                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 0))
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
                        ZStack {
                            LeafTicksView(leafVm.ticks())
                            LeafThumbSlideView(leafVm, .runXY)
                        }
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}


