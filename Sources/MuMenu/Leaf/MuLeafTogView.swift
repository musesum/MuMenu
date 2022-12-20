//  Created by warren on 5/10/22.

import SwiftUI

/// Toggle 0/1 (off/on)
struct MuLeafTogView: View {
    
    @ObservedObject var leafVm: MuLeafTogVm

    var body: some View {
        MuLeafView(leafVm) {
            MuLeafThumbTapView(leafVm: leafVm)
        }
    }
}
