//  created by musesum on 8/18/22.

import SwiftUI

struct LeafThumbTapView: View {

    @ObservedObject var leafVm: LeafVm
    let runwayType: RunwayType

    var panelVm: PanelVm { leafVm.panelVm }
    var color: Color { leafVm.spotlight ? .white : .gray }
    var thumbOffset: CGSize { leafVm.leafProto?.thumbValOffset(runwayType) ?? .zero }
    var togColor: Color { Layout.togColor(leafVm.thumbVal[0] > 0) }
    var diameter: Double { panelVm.thumbDiameter(.xy) }
    var togOffset: CGSize { CGSize(width:  Layout.radius-6, height: Layout.radius-6)}
  
    init(_ leafVm: LeafVm,
         _ runwayType: RunwayType) {
        self.leafVm = leafVm
        self.runwayType = runwayType
    }
    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width:  diameter, height: diameter)
                .offset(thumbOffset)
                .allowsHitTesting(false)

            IconView(leafVm, leafVm.node.icon, runwayType)
                .frame(width:  diameter, height: diameter)
                .offset(thumbOffset)

            Capsule()
                .fill(.black)
                .frame(width: 9, height: 9)
                .offset(togOffset)
                .allowsHitTesting(false)

            Capsule()
                .fill(togColor)
                .frame(width: 7, height: 7)
                .offset(togOffset)
                .allowsHitTesting(false)
        }
    }
}

