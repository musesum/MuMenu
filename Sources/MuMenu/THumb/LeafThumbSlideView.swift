//  created by musesum on 8/18/22.

import SwiftUI

public struct LeafThumbSlideView: View {

    @ObservedObject var leafVm: LeafVm
    let runwayType: LeafRunwayType

    var spotlight: Bool { leafVm.spotlight }
    var valueColor: Color { Layout.tapColor(spotlight) }
    var tweenColor: Color { Layout.tweColor(spotlight) }
    var thumbValueOffset: CGSize { leafVm.thumbValueOffset(runwayType) }
    var thumbTweenOffset: CGSize { leafVm.thumbTweenOffset(runwayType) }
    var thumbDiameter: Double { runwayType.thumbRadius - 2 }

    public init(_ leafVm: LeafVm,
                _ runwayType: LeafRunwayType) {
        self.leafVm = leafVm
        self.runwayType = runwayType
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

            IconView(leafVm, leafVm.menuTree.icon, runwayType)
                .frame(width: thumbDiameter, height: thumbDiameter)
                .offset(thumbValueOffset)
        }
    }
}
