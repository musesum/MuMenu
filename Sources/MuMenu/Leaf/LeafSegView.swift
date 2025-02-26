// created by musesum on 10/17/21.

import SwiftUI

struct LeafSegView: View {
    
    @ObservedObject var leafVm: LeafSegVm

    var body: some View {
        LeafView(leafVm) {
            LeafTicksView(leafVm.ticks())
            LeafThumbSlideView(leafVm, .runXY)
        }
    }
}

