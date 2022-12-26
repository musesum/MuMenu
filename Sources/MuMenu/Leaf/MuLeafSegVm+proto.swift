//  Created by warren on 9/10/22.

import SwiftUI
import Par // Visitor

extension MuLeafSegVm: MuLeafProtocol {

    /// user touch gesture inside runway
    public func touchLeaf(_ touchState: MuTouchState) {

        if touchState.phase == .began {
            touchThumbBegin()
            editing = true
        } else if !touchState.phase.isDone() {
            touchThumbNext()
            editing = true
        } else {
            editing = false
        }
        updateSync(Visitor())

        func touchThumbBegin() {
            let thumbPrev = thumb[0]
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbNext = normalizeTouch(touchDelta)
            let touchedInsideThumb = abs(thumbNext.distance(to: thumbPrev)) < thumbRadius
            thumbBeginΔ = touchedInsideThumb ? thumbPrev - thumbNext : .zero
            thumb[0] = thumbNext + thumbBeginΔ
        }
        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            if !runwayBounds.contains(touchState.pointNow) {
                // slowly erode thumbBegin∆ when out of bounds
                thumbBeginΔ = thumbBeginΔ * 0.85
            }
            let touchDelta = touchState.pointNow - runwayBounds.origin
            thumb[0] = normalizeTouch(touchDelta) + thumbBeginΔ
        }
    }

    public func refreshValue() {
        if let menuSync {
            range = menuSync.getRange(named: nodeType.name)
            if let val = menuSync.getAny(named: nodeType.name) as? Double {
                thumb[0] = scale(val, from: range, to: 0...1)
            } else {
                print("⁉️ refreshValue is not Double")
                thumb[0] = 0
            }
        }
    }
    
    public func updateLeaf(_ any: Any, _ visitor: Visitor) {
        visitor.startVisit(hash, visit)
        func visit() {
            editing = true
            switch any {
                case let v as Double:   thumb[0] = v
                case let v as [Double]: thumb[0] = v[0]
                default: break
            }
            editing = false
            updateSync(visitor)
        }
    }

    private func updateSync(_ visitor: Visitor) {
        menuSync?.setAny(named: nodeType.name, expanded, visitor)
        updatePeers(visitor)
    }

    public func valueText() -> String {
        range.upperBound > 1
        ? String(format: "%.f", scale(thumb[0], from: 0...1, to: range))
        : String(format: "%.1f", thumb[0])
    }

    public func thumbOffset() -> CGSize {
        panelVm.axis == .vertical
        ? CGSize(width: 1, height: (1-thumb[0]) * panelVm.runway)
        : CGSize(width: thumb[0] * panelVm.runway, height: 1)
    }

   
}
