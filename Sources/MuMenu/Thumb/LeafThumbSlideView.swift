//  created by musesum on 8/18/22.

import SwiftUI

public struct LeafThumbSlideView: View {

    @ObservedObject var leafVm: LeafVm
    let runwayType: LeafRunwayType
    var diameter: Double { runwayType.thumbRadius - 2 }
    var ticks: [CGSize]?
    var hasPlugin: Bool { leafVm.menuTree.flo.hasPlugins }
    public init(_ leafVm: LeafVm,
                _ runwayType: LeafRunwayType,
                _ ticks: [CGSize]? = nil) {
        self.leafVm = leafVm
        self.runwayType = runwayType
        self.ticks = ticks
    }
    public var body: some View {
        ZStack {
            if let ticks {
                LeafTicksView(ticks)
            }
            if hasPlugin {
                Capsule() // thumb tween
                    .fill(Menu.tweenColor(leafVm.spotlight ) )
                    .frame(width: diameter, height: diameter)
                    .offset(leafVm.runways.tweenOffset(runwayType))
                    .allowsHitTesting(false)
            }
            IconView(leafVm, leafVm.menuTree.icon, runwayType)
                .frame(width: diameter, height: diameter)
                .offset(leafVm.runways.valueOffset(runwayType))
        }
    }
}
