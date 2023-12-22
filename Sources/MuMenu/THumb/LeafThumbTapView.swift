//  created by musesum on 8/18/22.

import SwiftUI

struct LeafThumbTapView: View {

    @ObservedObject var leafVm: LeafVm
    var panelVm: PanelVm { leafVm.panelVm }
    var color: Color { leafVm.spotlight ? .white : .gray }
    var thumbOffset: CGSize { leafVm.leafProto?.thumbValOffset() ?? .zero }
    var togColor: Color { Layout.togColor(leafVm.thumbVal[0] > 0) }
    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(thumbOffset)
                .allowsHitTesting(false)

            IconView(nodeVm: leafVm, icon: leafVm.node.icon)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(thumbOffset)

            Capsule()
                .fill(.black)
                .frame(width: 9, height: 9)
                .offset(CGSize(width:  Layout.radius-6,
                               height: Layout.radius-6))
                .allowsHitTesting(false)

            Capsule()
                .fill(togColor)
                .frame(width: 7, height: 7)
                .offset(CGSize(width:  Layout.radius-6,
                               height: Layout.radius-6))
                .allowsHitTesting(false)
        }
    }
}

