// created by musesum on 10/17/21.

import SwiftUI

struct LeafValView: View {

    @ObservedObject var leafVm: LeafVm
    var body: some View {
        LeafView(leafVm) {
            LeafThumbSlideView(leafVm, .xy)
        }
    }
}

