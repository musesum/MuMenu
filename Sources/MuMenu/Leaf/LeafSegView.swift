// created by musesum on 10/17/21.

import SwiftUI

struct LeafSegView: View {

    @ObservedObject var leafVm: LeafSegVm

    var body: some View {
        LeafBezelView(leafVm, .runVal) {
            LeafThumbSlideView(leafVm, .runVal, leafVm.ticks())
        }
    }
}
