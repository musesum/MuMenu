//  Created by warren on 8/18/22.

import SwiftUI

struct MuLeafThumbSlideView: View {

    @ObservedObject var leafVm: MuLeafVm
    var panelVm: MuPanelVm { leafVm.panelVm }
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
                MuIconView(nodeVm: leafVm, icon: leafVm.node.icon)
                    .frame(width:  panelVm.thumbDiameter,
                           height: panelVm.thumbDiameter)
                    .offset(thumbValOffset)
            } else {
                MuIconView(nodeVm: leafVm, icon: leafVm.node.icon)
                    .frame(width:  panelVm.thumbDiameter,
                           height: panelVm.thumbDiameter)
                    .offset(thumbValOffset)
            }
        }
    }
}
