//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// 2d XY control
public class LeafXyzVm: LeafVm {
    
    var ranges = [String : ClosedRange<Double>]()

    override init (_ menuTree: MenuTree,
                   _ branchVm: BranchVm,
                   _ prevVm: NodeVm?) {
        
        super.init(menuTree, branchVm, prevVm)
        super.leafProto = self
        menuTree.leafProto = self // MuLeafProtocol for exchanging value

        // set ranges
        if let exprs = menuTree.model˚.exprs,
           let x = exprs.nameAny["x"] as? Scalar,
           let y = exprs.nameAny["y"] as? Scalar,
           let z = exprs.nameAny["z"] as? Scalar {

            ranges["x"] = x.range()
            ranges["y"] = y.range()
            ranges["z"] = z.range()
            
        } else {
            let scalars = menuTree.model˚.scalars()
            for scalar in scalars {
                ranges[scalar.name] = scalar.range()
            }
        }
        refreshValue(Visitor(0, .model))
    }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
   func ticks() -> [CGSize] {
        var result = [CGSize]()
        let lengthXYZ = self.panelVm.runwayXYZ
        let span = CGFloat(0.25)
        
        for w in stride(from: CGFloat(0), through: 1, by: span) {
            for h in stride(from: CGFloat(0), through: 1, by: span) {

                let tick = CGSize(width:  w * lengthXYZ.x,
                                  height: h * lengthXYZ.y)
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

        let pointNow = touchState.pointNow

        if touchState.phase == .began {
            if touchState.touchBeginCount > 0 {
                tapThumb()
                editing = true
            } else {
                touchThumbBegin()
                editing = true
            }

        } else if !touchState.phase.done {
            touchThumbNext()
            editing = true
        } else {
            editing = false
        }
        syncVal(visit)

        func tapThumb() {

            let touchOffset = SIMD2<Double>(touchState.pointNow - bounds.origin)
            let thumbPrior = panelVm.normalizeTouch(xy: touchOffset)
            thumb.value = thumbPrior.quantize(4)
            thumb.delta = touchOffset - thumbCenter(runway)
            syncVal(visit)
        }

        func touchThumbBegin() {
            updateRunway(touchState.pointNow)
            let touchOffset = runway.offset(pointNow, bounds)
            let oldCenter = thumbCenter(runway)
            let deltaOffset = touchOffset - oldCenter
            let insideThumb = deltaOffset.distance(SIMD2<Double>.zero) < runway.thumbRadius
            thumb.delta = insideThumb ? deltaOffset : .zero
            touchThumbNext()
        }

        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            let touchOffset = runway.offset(pointNow, bounds)
            let nextThumb = touchOffset - thumb.delta
            thumb.value = panelVm.normalizeTouch(xy: nextThumb).clamped(to: 0...1)
            PrintLog("touchThumbNext pointNow\(pointNow.digits(2))  \(runway.rawValue) \(thumb.value.digits(2)) ")
        }
    }
    /// user double tapped a parent node
    override func tapLeaf() {
        resetOrigin()
    }

}
