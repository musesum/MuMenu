// Created by warren on 10/17/21.

import SwiftUI

struct MuLeafSegView: View {
    
    @ObservedObject var leafVm: MuLeafSegVm

    var body: some View {
        MuLeafView(leafVm) {
            // tick marks
            ForEach(leafVm.ticks, id: \.self) {
                Capsule()
                    .fill(.gray)
                    .frame(width: 4, height: 4)
                    .offset(CGSize(width: $0.width, height: $0.height))
                    .allowsHitTesting(false)
            }
            // thumb dot
            MuLeafThumbSlideView(leafVm: leafVm)
        }
    }
}

