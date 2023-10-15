// created by musesum on 10/17/21.

import SwiftUI

struct MuLeafValView: View {

    @ObservedObject var leafVm: MuLeafVm
    var body: some View {
        MuLeafView(leafVm) {
            MuLeafThumbSlideView(leafVm: leafVm)
        }
    }
}

