//  Created by warren on 12/5/22.

import SwiftUI

struct MuLeafPeerView: View {

    @ObservedObject var leafVm: MuLeafPeerVm

    var body: some View {

        MuLeafView(leafVm) {
            PeersView(peersVm: leafVm.peersVm)
        }
    }
}

