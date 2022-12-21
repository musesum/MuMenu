//  Created by warren on 9/10/22.


import Foundation
import Par

extension MuLeafValVm: MuLeafProtocol {

    /// user touch gesture inside runway
    public func touchLeaf(_ touchState: MuTouchState) {

        if touchState.phase == .began {
            touchThumbBegin()
            editing = true
        } else if !touchState.phase.isDone()  {
            touchThumbNext()
            editing = true
        } else {
            editing = false
        }
        updateSync()

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

    public func refreshValue() {
        thumb[0] = normalizeNamed(nodeType.name)
        range = menuSync?.getRange(named: nodeType.name) ?? 0...1
    }

    public func updateLeaf(_ any: Any,_ visitor: Visitor) {
        visitor.startVisit(hash, visit)
        func visit() {
            if let v = any as? [Double] {
                editing = true
                thumb[0] = CGFloat(scale(v[0], from: range, to: 0...1))
                editing = false
            }
            updateSync(visitor)
        }
    }

    public func updateSync(_ visitor: Visitor = Visitor()) {

            menuSync?.setAny(named: nodeType.name, expanded, visitor)
            updatePeers(visitor)
    
    }
    public func valueText() -> String {
        String(format: "%.2f", expanded)
    }
    public func thumbOffset() -> CGSize {
        panelVm.axis == .vertical
        ? CGSize(width: 1, height: (1-thumb[0]) * panelVm.runway)
        : CGSize(width: thumb[0] * panelVm.runway, height: 1)
    }
}
