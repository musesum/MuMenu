//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo
import MuExtensions

/// 2d XY control
public class LeafXyVm: LeafVm {
    
    var ranges = [String : ClosedRange<Double>]()

    override init (_ node: FloNode,
                   _ branchVm: BranchVm,
                   _ prevVm: NodeVm?) {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self)  //MuLeafProtocol for exchanging value

        // set ranges
        if let exprs = node.modelFlo.exprs {
            for name in ["x","y","z"] {
                if let scalar = exprs.nameAny[name] as? FloValScalar {
                    ranges[name] = scalar.range()
                }
            }
        } else {
            let scalars = node.modelFlo.scalars()
            for scalar in scalars {
                ranges[scalar.name] = scalar.range()
            }
        }
        refreshValue(Visitor(.model))
    }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
    func ticks() -> [CGSize] {

        var result = [CGSize]()
        let runway = self.panelVm.runwayXY
        let span = CGFloat(0.25)

        for w in stride(from: CGFloat(0), through: 1, by: span) {
            for h in stride(from: CGFloat(0), through: 1, by: span) {

                let tick = CGSize(width:  w * runway.x,
                                  height: h * runway.y)
                result.append(tick)
            }
        }
        return result
    }


    func expand(named: String, _ value: CGFloat) -> Double {

        let range = ranges[named] ?? 0...1
        let result = scale(Double(value), from: 0...1, to: range)
        return result
    }

      /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
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
        syncVal(visit)

        func tapThumb() {
            guard let runwayBounds = runway(.xy) else { return }
            let touchOffset = SIMD2<Double>(touchState.pointNow - runwayBounds.origin)
            let thumbPrior = panelVm.normalizeTouch(xy: touchOffset)
            thumbVal = thumbPrior.quantize(4)
            thumbDelta = touchOffset - thumbCenter(.xy)
            syncVal(visit)
        }

        func touchThumbBegin() {
            guard let runwayBounds = runway(.xy) else { return }
            let touchOffset = SIMD2<Double>(touchState.pointNow - runwayBounds.origin)
            let deltaOffset = touchOffset - thumbCenter(.xy)
            let insideThumb = deltaOffset.distance(SIMD2<Double>.zero) < panelVm.thumbRadius

            thumbDelta = insideThumb ? deltaOffset : .zero
            touchThumbNext()
        }

        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            guard let runwayBounds = runway(.xy) else { return }
            if !runwayBounds.contains(touchState.pointNow) {
                // slowly erode delta when out of bounds
                thumbDelta =  thumbDelta * 0.88
            }
            let touchOffset = SIMD2<Double>(touchState.pointNow - runwayBounds.origin)
            let nextThumb = touchOffset - thumbDelta
            thumbVal = panelVm.normalizeTouch(xy: nextThumb).clamped(to: 0...1)

        }
    }
    
}
