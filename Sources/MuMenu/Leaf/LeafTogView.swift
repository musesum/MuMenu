//  created by musesum on 5/10/22.

import SwiftUI

/// Toggle 0/1 (off/on)
struct LeafTogView: View {
    
    @ObservedObject var leafVm: LeafTogVm

    var body: some View {
        LeafView(leafVm) {
            LeafThumbTapView(leafVm, .xy)
        }
    }
}
