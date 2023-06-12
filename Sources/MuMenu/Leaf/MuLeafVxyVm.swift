//  Created by warren on 5/10/22.

import SwiftUI
import MuPar

/// 2d XY control
public class MuLeafVxyVm: MuLeafVm {
    
    var ranges = [String : ClosedRange<Double>]()

    override init (_ node: MuFloNode,
                   _ branchVm: MuBranchVm,
                   _ prevVm: MuNodeVm?) {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self)  //MuLeafProtocol for exchanging value
        refreshValue(Visitor(.model))
    }
//    func normalizeNamed(_ name: String,
//                        _ range: ClosedRange<Double>?) -> Double {
//        
//        let val = (menuSync?.getMenuAny(named: name) as? Double) ?? .zero
//        let norm = scale(val, from: range ?? 0...1, to: 0...1)
//        return norm
//    }
    func expand(named: String, _ value: CGFloat) -> Double {

        let range = ranges[named] ?? 0...1
        let result = scale(Double(value), from: 0...1, to: range)
        return result
    }

    /// Tick marks for double touch alignments
    /// shown at center, corner, and sides.
    /// So: NW, N, NE, E, SE, S, SW, W, Center
    var nearestTick: CGPoint {
        CGPoint(x: round(thumbNext[0] * 4) / 4,
                y: round(thumbNext[1] * 4) / 4)
    }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
    lazy var ticks: [CGSize] = {
        var result = [CGSize]()
        let runway = self.panelVm.runwayXY
        let radius = self.panelVm.thumbRadius
        let span = CGFloat(0.25)
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

    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: MuTouchState,
                                   _ visit: Visitor) {

        if touchState.phase == .began {
            if touchState.touchBeginCount > 0 {
                tapThumb()
                editing = true
            } else {
                touchThumbBegin()
                editing = true
            }
        } else if !touchState.phase.isDone() {
            touchThumbNext()
            editing = true
        } else {
            editing = false
        }
        updateLeafPeers(visit)

        func tapThumb() {
            let touchOffset = touchState.pointNow - runwayBounds.origin
            let thumbPrior = panelVm.normalizeTouch(xy: touchOffset)
            thumbNext = quantizeThumb(thumbPrior)
            thumbDelta = touchOffset - thumbCenter()
            syncNext(visit)
        }

        func touchThumbBegin() {

            let touchOffset = touchState.pointNow - runwayBounds.origin
            let deltaOffset = touchOffset - thumbCenter()
            let insideThumb = deltaOffset.distance(.zero) < panelVm.thumbRadius

            thumbDelta = insideThumb ? deltaOffset : .zero
            touchThumbNext()
        }

        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            if !runwayBounds.contains(touchState.pointNow) {
                // slowly erode delta when out of bounds
                thumbDelta =  thumbDelta * 0.88
            }
            let touchOffset = touchState.pointNow - runwayBounds.origin
            let nextThumb = touchOffset - thumbDelta
            let normThumb = panelVm.normalizeTouch(xy: nextThumb)
            thumbNext = [normThumb[0].clamped(to: 0...1),
                         normThumb[1].clamped(to: 0...1)]
            syncNext(visit) //???
        }
        /// double touch will align thumb to center, corners or sides.
        func quantizeThumb(_ point: [Double]) -> [Double] {

            let x = round(point[0] * 4) / 4
            let y = round(point[1] * 4) / 4
            return [x,y]
        }
    }
    
}
