//  Created by warren on 8/18/22.

import SwiftUI

struct MuLeafThumbTapView: View {

    @ObservedObject var leafVm: MuLeafVm
    var panelVm: MuPanelVm { leafVm.panelVm }
    var color: Color { leafVm.spotlight ? .white : .gray }
    var thumbOffset: CGSize { leafVm.leafProto?.thumbOffset() ?? .zero }

    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(thumbOffset)
                .allowsHitTesting(false)

            MuIconView(nodeVm: leafVm, icon: leafVm.node.icon)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(thumbOffset)
        }
    }
}

