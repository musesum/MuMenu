//  created by musesum on 12/5/22.

import SwiftUI
import MuPeer

struct LeafPeerView: View {

    @ObservedObject var leafVm: LeafPeerVm
    var panelVm: PanelVm { leafVm.panelVm }

    var body: some View {
        VStack {
            if panelVm.cornerAxis.corner.upper {
                
                LeafBodyView(leafVm) {
                    PeersView(leafVm.peersVm)
                }
                LeafTitleView(leafVm)
            } else {
                LeafTitleView(leafVm)
                LeafBodyView(leafVm) {
                    PeersView(leafVm.peersVm)
                }
            }
        }
    }
}

