//  Created by warren on 12/10/21.

import SwiftUI
import Par

/// 1d slider control
public class MuLeafValVm: MuLeafVm {

    var range: ClosedRange<Double> = 0...1

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) // MuLeaf delegate for setting value
        refreshValue()
    }

    func normalizeNamed(_ name: String) -> CGFloat {
        let val = (menuSync?.getAny(named: name) as? Double) ?? .zero
        let norm = scale(val, from: range, to: 0...1)
        return CGFloat(norm)
    }
    /// scale up normalized to defined range
    var expanded: Double {
        scale(thumb[0], from: 0...1, to: range)
    }
    func normalizeTouch(_ point: CGPoint) -> CGFloat {
        let v = panelVm.isVertical ? point.y : point.x
        let vv = panelVm.normalizeTouch(v: v)
        return vv 
    }

    /// normalized thumb radius
    lazy var thumbRadius: CGFloat = {
        Layout.diameter / max(runwayBounds.height,runwayBounds.width) / 2
    }()

    /// `touchBegin` inside thumb will Not move thumb.
    /// So, determing delta from center at touchState.begin
    var thumbBeginΔ = CGFloat.zero


    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: MuTouchState,
                                   visitor: Visitor = Visitor()) {

        if touchState.phase == .began {
            touchThumbBegin()
            editing = true
        } else if !touchState.phase.isDone()  {
            touchThumbNext()
            editing = true
        } else {
            editing = false
        }
        updateSync(visitor)

        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            if !runwayBounds.contains(touchState.pointNow) {
                // slowly erode thumbBegin∆ when out of bounds
                thumbBeginΔ = thumbBeginΔ * 0.85
            }
            let touchDelta = touchState.pointNow - runwayBounds.origin
            thumb[0] = normalizeTouch(touchDelta) + thumbBeginΔ
        }
        func touchThumbBegin() {
            let thumbPrev = thumb[0]
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbNext = normalizeTouch(touchDelta)
            let touchedInsideThumb = abs(thumbNext.distance(to: thumbPrev)) < thumbRadius
            thumbBeginΔ = touchedInsideThumb ? thumbPrev - thumbNext : .zero
            thumb[0] = thumbNext + thumbBeginΔ
        }
    }
    func updateSync(_ visitor: Visitor) {

        if let menuSync, menuSync.setAny(named: nodeType.name, expanded, visitor) {

            updateLeafPeers(visitor)
        }
    }
}


