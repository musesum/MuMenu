//  created by musesum on 12/5/22.

import SwiftUI
import MuPeer

struct LeafPeerView: View {

    var leafVm: LeafPeerVm
    var panelVm: PanelVm { leafVm.panelVm }


    var body: some View {
        VStack {
            if panelVm.corner.cornerOp.upper {
                
                LeafBezelView(leafVm, .none) {
                    PeersView(leafVm.peersVm)
                }
                LeafHeaderView(leafVm)
            } else {
                LeafHeaderView(leafVm)
                LeafBezelView(leafVm, .none) {
                    PeersView(leafVm.peersVm)
                }
            }
        }
    }
}
