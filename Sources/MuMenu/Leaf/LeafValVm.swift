//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// 1d slider control
public class LeafValVm: LeafVm {

    var range: ClosedRange<Double> = 0...1

    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {
        
        super.init(menuTree, branchVm, prevVm)
        super.leafProto = self
        menuTree.leafProto = self 

        setRanges()
        refreshValue(Visitor(0, .bind))
    }
    /// normalize to and from scalar range
    func setRanges() {
        if let exprs = menuTree.model˚.exprs {
            if let x = exprs.nameAny["x"] as? Scalar {
                range = x.range()
            } else if let y = exprs.nameAny["y"] as? Scalar {
                range = y.range()
            } else if let scalar = exprs.nameAny.values.first as? Scalar {
                range = scalar.range()
            }
        }
    }

    /// scale up normalized to defined range
    var expanded: Double {
        scale(thumb.value.x, from: 0...1, to: range)
    }
    func normalizeTouch(_ point: CGPoint) -> CGFloat {
        let v = panelVm.isVertical ? point.y : point.x
        let vv = panelVm.normalizeTouch(v: v)
        return vv 
    }

    /// `touchBegin` inside thumb will Not move thumb.
    /// So, determing delta from center at touchState.begin
    var thumbBeginΔ = CGFloat.zero


    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {
        if touchState.phase == .began {
            touchThumbBegin()
            editing = true
        } else if !touchState.phase.done  {
            touchThumbNext()
            editing = true
        } else {
            editing = false
        }
        syncVal(visit)

        func touchThumbBegin() {
            updateRunway(touchState.pointNow)
            let thumbPrev = thumb.value.x
            let touchDelta = touchState.pointNow - bounds.origin
            let thumbDelta = normalizeTouch(touchDelta)
            let isInsideThumb = abs(thumbDelta.distance(to: thumbPrev)) < thumbNormRadius
            thumbBeginΔ = isInsideThumb ? thumbPrev - thumbDelta : .zero
            thumb.value.x = thumbDelta + thumbBeginΔ

        }
        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            if !bounds.contains(touchState.pointNow) {
                // slowly erode thumbBegin∆ when out of bounds
                thumbBeginΔ = thumbBeginΔ * 0.85
            }
            let touchDelta = touchState.pointNow - bounds.origin
            thumb.value.x = normalizeTouch(touchDelta) + thumbBeginΔ
        }
    }
    /// user double tapped a parent node
    override func tapLeaf() {
        resetOrigin()
    }

}


