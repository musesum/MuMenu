//  created by musesum on 12/5/22.

import SwiftUI
import MuPeer

struct MuLeafPeerView: View {

    @ObservedObject var leafVm: MuLeafPeerVm
    var panelVm: MuPanelVm { leafVm.panelVm }

    var body: some View {
        VStack {
            if panelVm.cornerAxis.corner.upper {
                
                MuLeafBodyView(leafVm) {
                    PeersView(leafVm.peersVm)
                }
                MuLeafTitleView(leafVm)
            } else {
                MuLeafTitleView(leafVm)
                MuLeafBodyView(leafVm) {
                    PeersView(leafVm.peersVm)
                }
            }
        }
    }
}

