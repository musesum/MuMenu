//  created by musesum on 8/18/22.

import SwiftUI

struct LeafThumbTapView: View {

    @ObservedObject var leafVm: LeafVm
    let runwayType: LeafRunwayType

    var panelVm: PanelVm { leafVm.panelVm }
    var color: Color { leafVm.spotlight ? .white : .gray }
    var thumbOffset: CGSize { leafVm.thumbValueOffset(runwayType) }
    var togColor: Color {
        if let thumb = leafVm.runways.thumb() {
            return Layout.togColor(thumb.value[0] > 0)
        } else {
            return Layout.togColor(false)
        }
    }
    var diameter: Double { panelVm.thumbDiameter(.runXY) }
    var togOffset: CGSize { CGSize(width:  Layout.radius-6, height: Layout.radius-6)}
  
    init(_ leafVm: LeafVm,
         _ runwayType: LeafRunwayType) {
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

            IconView(leafVm, leafVm.menuTree.icon, runwayType)
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

