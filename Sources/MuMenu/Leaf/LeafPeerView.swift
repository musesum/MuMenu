#if !os(watchOS)
//  created by musesum on 12/5/22.

import SwiftUI
import MuPeers

struct LeafPeerView: View {

    @ObservedObject public var leafVm: LeafPeerVm
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
                // the bonjour switch, at the corner the header leaves open
                Button {
                    leafVm.bonjourOn.toggle()
                } label: {
                    Image(systemName: leafVm.bonjourOn
                          ? "antenna.radiowaves.left.and.right"
                          : "antenna.radiowaves.left.and.right.slash")
                        .foregroundColor(leafVm.bonjourOn
                                         ? .white
                                         : .white.opacity(0.35))
                }
                .frame(width: 32, height: 32)
            }
            LeafBezelView(leafVm, .none) {
                PeersView()
            }
        }
    }
}
#endif
