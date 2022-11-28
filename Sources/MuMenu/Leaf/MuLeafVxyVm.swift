//  Created by warren on 5/10/22.

import SwiftUI

/// 2d XY control
public class MuLeafVxyVm: MuLeafVm {
    
    var thumb: CGPoint = .zero /// normalized to 0...1
    var ranges = [String : ClosedRange<Double>]()

    override init (_ node: MuNode,
                   _ branchVm: MuBranchVm,
                   _ prevVm: MuNodeVm?) {
        
        super.init(node, branchVm, prevVm)
        node.proxies.append(self)  // MuLeaf delegate for setting value
        refreshValue()
    }
    func normalizeNamed(_ name: String, _ range: ClosedRange<Double>?) -> CGFloat {
        let val = (nodeProto?.getAny(named: name) as? Double) ?? .zero
        let norm = scale(val, from: range ?? 0...1, to: 0...1)
        return CGFloat(norm)
    }
    func expand(named: String, _ value: CGFloat) -> Double {

        let range = ranges[named] ?? 0...1
        let result = scale(Double(value), from: 0...1, to: range)
        return result
    }

    /// Tick marks for double touch alignments
    /// shown at center, corner, and sides.
    /// So: NW, N, NE, E, SE, S, SW, W, Center
    var nearestTick: CGPoint {
        CGPoint(x: round(thumb.x * 2) / 2,
                y: round(thumb.y * 2) / 2)
    }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
    lazy var ticks: [CGSize] = {
        var result = [CGSize]()
        let runway = self.panelVm.runwayXY
        let radius = self.panelVm.thumbRadius
        let span = CGFloat(0.5)
        let margin = Layout.radius - 2
        for w in stride(from: CGFloat(0), through: 1, by: span) {
            for h in stride(from: CGFloat(0), through: 1, by: span) {

                let tick = CGSize(width:  w * runway.x,
                                  height: h * runway.y)
                result.append(tick)
            }
        }
        return result
    }()

    /// normalized thumb radius
    lazy var thumbRadius: CGFloat = {
        Layout.diameter / max(runwayBounds.height,runwayBounds.width) / 2
    }()

    /// `touchBegin` inside thumb will probably be off-center.
    /// To avoid a sudden jump, thumbBeginΔ adds an offset.
    var thumbBeginΔ = CGPoint.zero
}
