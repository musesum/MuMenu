//  Created by warren on 5/10/22.

import SwiftUI

struct MuLeafTapView: View {

    @ObservedObject var leafVm: MuLeafTapVm
    var body: some View {
        MuLeafView(leafVm) {
            MuLeafThumbTapView(leafVm: leafVm, value: leafVm.thumb[0])
                .offset(CGSize(width: 1, height: -1))
        }
    }
}
