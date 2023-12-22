//  created by musesum on 8/18/22.

import SwiftUI

struct LeafThumbSlideView: View {

    @ObservedObject var leafVm: LeafVm
    var panelVm: PanelVm { leafVm.panelVm }
    var spotlight: Bool { leafVm.spotlight }
    var valColor: Color { Layout.tapColor(spotlight) }
    var tweColor: Color { Layout.tweColor(spotlight) }
    var thumbValOffset: CGSize { leafVm.leafProto?.thumbValOffset() ?? .zero }
    var thumbTweOffset: CGSize { leafVm.leafProto?.thumbTweOffset() ?? .zero }

    var body: some View {
        ZStack {
            Capsule()
                .fill(tweColor)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(thumbTweOffset)
                .allowsHitTesting(false)

            Capsule()
                .fill(valColor)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(thumbValOffset)
                .allowsHitTesting(false)

            if spotlight {
                IconView(nodeVm: leafVm, icon: leafVm.node.icon)
                    .frame(width:  panelVm.thumbDiameter,
                           height: panelVm.thumbDiameter)
                    .offset(thumbValOffset)
            } else {
                IconView(nodeVm: leafVm, icon: leafVm.node.icon)
                    .frame(width:  panelVm.thumbDiameter,
                           height: panelVm.thumbDiameter)
                    .offset(thumbValOffset)
            }
        }
    }
}
