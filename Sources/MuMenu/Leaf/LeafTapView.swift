//  created by musesum on 5/10/22.

import SwiftUI

struct LeafTapView: View {

    @ObservedObject var leafVm: LeafTapVm
    var body: some View {
        LeafView(leafVm) {
            LeafThumbTapView(leafVm, .xy)
                .offset(CGSize(width: 1, height: -1))
        }
    }
}
