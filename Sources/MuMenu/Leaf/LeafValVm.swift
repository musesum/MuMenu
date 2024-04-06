//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// 1d slider control
public class LeafValVm: LeafVm {

    var range: ClosedRange<Double> = 0...1

    init (_ node: FloNode,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self)

        setRanges()
        refreshValue(Visitor(.bind))
    }
    /// normalize to and from scalar range
    func setRanges() {
        if let exprs = node.modelFlo.exprs {
            if let x = exprs.nameAny["x"] as? FloValScalar {
                range = x.range()
            } else if let y = exprs.nameAny["y"] as? FloValScalar {
                range = y.range()
            } else if let scalar = exprs.nameAny.values.first as? FloValScalar {
                range = scalar.range()
            }
        }
    }

    /// scale up normalized to defined range
    var expanded: Double {
        scale(thumbVal.x, from: 0...1, to: range)
    }
    func normalizeTouch(_ point: CGPoint) -> CGFloat {
        let v = panelVm.isVertical ? point.y : point.x
        let vv = panelVm.normalizeTouch(v: v)
        return vv 
    }

//    /// normalized thumb radius
//    lazy var thumbRadius: CGFloat = {
//        Layout.diameter / max(runwayBounds.height,runwayBounds.width) / 2
//    }()

    /// `touchBegin` inside thumb will Not move thumb.
    /// So, determing delta from center at touchState.begin
    var thumbBeginΔ = CGFloat.zero


    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {

        if touchState.phase == .began {
            touchThumbBegin()
            editing = true
        } else if !touchState.phase.isDone()  {
            touchThumbNext()
            editing = true
        } else {
            editing = false
        }
        syncVal(visit)

        func touchThumbBegin() {
            let thumbPrev = thumbVal.x
            let touchDelta = touchState.pointNow - (runway(.xy)?.origin ?? .zero)
            let thumbDelta = normalizeTouch(touchDelta)
            let touchedInsideThumb = abs(thumbDelta.distance(to: thumbPrev)) < thumbNormRadius()
            thumbBeginΔ = touchedInsideThumb ? thumbPrev - thumbDelta : .zero
            thumbVal.x = thumbDelta + thumbBeginΔ

        }
        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            guard let runwayBounds = runway(.xy) else { return }
            if !runwayBounds.contains(touchState.pointNow) {
                // slowly erode thumbBegin∆ when out of bounds
                thumbBeginΔ = thumbBeginΔ * 0.85
            }
            let touchDelta = touchState.pointNow - runwayBounds.origin
            thumbVal.x = normalizeTouch(touchDelta) + thumbBeginΔ
        }
    }
    
}


