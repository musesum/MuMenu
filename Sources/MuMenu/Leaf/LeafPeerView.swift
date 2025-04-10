//  created by musesum on 12/5/22.

import SwiftUI
import MuPeer

struct LeafPeerView: View {

    var leafVm: LeafPeerVm

    var body: some View {
        VStack {
            LeafHeaderTitleView(leafVm, inset: -64)
            LeafBezelView(leafVm, .none) {
                PeersView(leafVm.peersVm)
            }
        }
    }
}
