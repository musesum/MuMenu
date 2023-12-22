// created by musesum on 10/17/21.

import SwiftUI

struct LeafSegView: View {
    
    @ObservedObject var leafVm: LeafSegVm

    var body: some View {
        LeafView(leafVm) {
            // tick marks
            ForEach(leafVm.ticks, id: \.self) {
                Capsule()
                    .fill(.gray)
                    .frame(width: 4, height: 4)
                    .offset(CGSize(width: $0.width, height: $0.height))
                    .allowsHitTesting(false)
            }
            // thumb dot
            LeafThumbSlideView(leafVm: leafVm)
        }
    }
}

