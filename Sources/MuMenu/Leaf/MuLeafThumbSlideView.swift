//  Created by warren on 8/18/22.

import SwiftUI

struct MuLeafThumbSlideView: View {

    @ObservedObject var leafVm: MuLeafVm
    var panelVm: MuPanelVm { leafVm.panelVm }
    var spotlight: Bool { leafVm.spotlight }
    var color: Color { Layout.tapColor(spotlight) }

    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(leafVm.thumbOffset())
                .allowsHitTesting(false)

            if spotlight {
                MuIconView(nodeVm: leafVm, icon: leafVm.node.icon)
                    .frame(width:  panelVm.thumbDiameter,
                           height: panelVm.thumbDiameter)
                    .offset(leafVm.thumbOffset())
            } else {
                MuIconView(nodeVm: leafVm, icon: leafVm.node.icon)
                    .frame(width:  panelVm.thumbDiameter,
                           height: panelVm.thumbDiameter)
                    .offset(leafVm.thumbOffset())
            }
        }
    }
}
