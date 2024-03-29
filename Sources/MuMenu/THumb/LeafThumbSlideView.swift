//  created by musesum on 8/18/22.

import SwiftUI

public struct LeafThumbSlideView: View {

    @ObservedObject var leafVm: LeafVm
    let runwayType: RunwayType

    var panelVm: PanelVm { leafVm.panelVm }
    var spotlight: Bool { leafVm.spotlight }
    var valColor: Color { Layout.tapColor(spotlight) }
    var tweColor: Color { Layout.tweColor(spotlight) }
    var proto: LeafProtocol? { leafVm.leafProto }
    var thumbValOffset: CGSize { proto?.thumbValOffset(runwayType) ?? .zero }
    var thumbTweOffset: CGSize { proto?.thumbTweOffset(runwayType) ?? .zero }
    var thumbDiameter: Double { panelVm.thumbDiameter(runwayType)}

    public init(_ leafVm: LeafVm,
                _ runwayType: RunwayType) {
        self.leafVm = leafVm
        self.runwayType = runwayType
    }
    public var body: some View {
        ZStack {
            Capsule() // thumb tween
                .fill(tweColor)
                .frame(width: thumbDiameter, height: thumbDiameter)
                .offset(thumbTweOffset)
                .allowsHitTesting(false)

            Capsule() // thumb value
                .fill(valColor)
                .frame(width: thumbDiameter, height: thumbDiameter)
                .offset(thumbValOffset)
                .allowsHitTesting(false)

            IconView(leafVm, leafVm.node.icon, runwayType)
                .frame(width: thumbDiameter, height: thumbDiameter)
                .offset(thumbValOffset)
        }
    }
}
