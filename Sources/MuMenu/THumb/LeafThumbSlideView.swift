//  created by musesum on 8/18/22.

import SwiftUI

public struct LeafThumbSlideView: View {

    @ObservedObject var leafVm: LeafVm
    let runway: Runway

    var spotlight: Bool { leafVm.spotlight }
    var valueColor: Color { Layout.tapColor(spotlight) }
    var tweenColor: Color { Layout.tweColor(spotlight) }
    var proto: LeafProtocol? { leafVm.leafProto }
    var thumbValueOffset: CGSize { proto?.thumbValueOffset(runway) ?? .zero }
    var thumbTweenOffset: CGSize { proto?.thumbTweenOffset(runway) ?? .zero }
    var thumbDiameter: Double { runway.thumbRadius - 2 }

    public init(_ leafVm: LeafVm,
                _ runway: Runway) {
        self.leafVm = leafVm
        self.runway = runway
    }
    public var body: some View {
        ZStack {
            Capsule() // thumb tween
                .fill(tweenColor)
                .frame(width: thumbDiameter, height: thumbDiameter)
                .offset(thumbTweenOffset)
                .allowsHitTesting(false)

            Capsule() // thumb value
                .fill(valueColor)
                .frame(width: thumbDiameter, height: thumbDiameter)
                .offset(thumbValueOffset)
                .allowsHitTesting(false)

            IconView(leafVm, leafVm.menuTree.icon, runway)
                .frame(width: thumbDiameter, height: thumbDiameter)
                .offset(thumbValueOffset)
        }
    }
}
