//  created by musesum on 8/18/22.

import SwiftUI

struct LeafThumbTapView: View {

    @ObservedObject var leafVm: LeafVm
    let runway: Runway

    var panelVm: PanelVm { leafVm.panelVm }
    var color: Color { leafVm.spotlight ? .white : .gray }
    var thumbOffset: CGSize { leafVm.leafProto?.thumbValueOffset(runway) ?? .zero }
    var togColor: Color { Layout.togColor(leafVm.thumb.value[0] > 0) }
    var diameter: Double { panelVm.thumbDiameter(.runXY) }
    var togOffset: CGSize { CGSize(width:  Layout.radius-6, height: Layout.radius-6)}
  
    init(_ leafVm: LeafVm,
         _ runway: Runway) {
        self.leafVm = leafVm
        self.runway = runway
    }
    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width:  diameter, height: diameter)
                .offset(thumbOffset)
                .allowsHitTesting(false)

            IconView(leafVm, leafVm.menuTree.icon, runway)
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

