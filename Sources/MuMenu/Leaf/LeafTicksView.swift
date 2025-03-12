// created by musesum on 3/28/24

import SwiftUI

public struct LeafTicksView: View {

    let ticks: [CGSize]
    public init(_ ticks: [CGSize]) {
        self.ticks = ticks
    }

    public var body: some View {
        ZStack {
            ForEach(ticks, id: \.self) {
                Capsule()
                    .fill(.gray)
                    .frame(width: 4, height: 4)
                    .offset(CGSize(width: $0.width, height: $0.height))
                    .allowsHitTesting(false)
            }
        }
    }
}
