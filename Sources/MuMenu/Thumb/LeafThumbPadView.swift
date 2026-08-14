//  created by musesum on 7/11/26.

import SwiftUI

/// dual-thumb pad for xyzw leaves: the active pair (XY or WZ) renders as the
/// filled icon thumb on top; the inactive pair as a dotted outline beneath.
/// Tapping the uncovered dotted thumb swaps the active control
/// (LeafRunways.touchLeaf/beginRunway flips `activePad`).
public struct LeafThumbPadView: View {

    @ObservedObject var leafVm: LeafVm
    var ticks: [CGSize]?

    var active: LeafRunwayType { leafVm.runways.activePad }
    var inactive: LeafRunwayType { active == .runXY ? .runWZ : .runXY }
    var diameter: Double { LeafRunwayType.runXY.thumbRadius - 2 }

    public init(_ leafVm: LeafVm,
                _ ticks: [CGSize]? = nil) {
        self.leafVm = leafVm
        self.ticks = ticks
    }
    public var body: some View {
        ZStack {
            if let ticks {
                LeafTicksView(ticks)
            }
            Circle() // inactive pair: dotted stroke, no fill, under
                .stroke(Menu.strokeColor(false),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .frame(width: diameter, height: diameter)
                .offset(leafVm.runways.valueOffset(inactive))
                .allowsHitTesting(false)
                .id(leafVm.refresh)
            LeafThumbSlideView(leafVm, active) // active pair: filled, on top
        }
    }
}
