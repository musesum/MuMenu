//  created by musesum on 12/5/22.

import SwiftUI
import MuPeers

struct LeafPeerView: View {

    public var leafVm: LeafPeerVm
    @State private var findPeers = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    findPeers.toggle()
                } label: {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.white)
                }
                .frame(width: 32, height: 32)
                LeafHeaderTitleView(leafVm, inset: 0)
                Spacer()
            }
            LeafBezelView(leafVm, .none) {
                PeersView(leafVm.share.peers)
            }
        }
    }
}
