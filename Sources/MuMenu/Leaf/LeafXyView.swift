//  created by musesum on 5/10/22.

import SwiftUI
import MuExtensions

public struct LeafXyView: View {

    @ObservedObject var leafVm: LeafXyVm

    public var body: some View {
        VStack {

            LeafTitleView(leafVm)
            LeafBezelView(leafVm, .xy) {
                ZStack {
                    LeafTicksView(leafVm.ticks())
                    LeafThumbSlideView(leafVm, .xy)
                }
            }
        }
    }
}
