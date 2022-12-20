//  Created by warren on 9/10/22.


import Foundation

extension MuLeafValVm: MuLeafProtocol {

    /// user touch gesture inside runway
    public func touchLeaf(_ touchState: MuTouchState) {

        if touchState.phase == .began {
            touchThumbBegin()
            updateView()
            editing = true
        } else if !touchState.phase.isDone()  {
            touchThumbNext()
            updateView()
            editing = true
        } else {
            editing = false
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
        func touchThumbBegin() {
            let thumbPrev = thumb[0]
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbNext = normalizeTouch(touchDelta)
            let touchedInsideThumb = abs(thumbNext.distance(to: thumbPrev)) < thumbRadius
            thumbBeginΔ = touchedInsideThumb ? thumbPrev - thumbNext : .zero
            thumb[0] = thumbNext + thumbBeginΔ
        }
    }
    
    // MARK: - Value

    public override func refreshValue() {
        thumb[0] = normalizeNamed(nodeType.name)
        range = menuSync?.getRange(named: nodeType.name) ?? 0...1
    }

    public func updateLeaf(_ any: Any) {
        if let v = any as? Double {
            editing = true
            thumb[0] = CGFloat(scale(v, from: range, to: 0...1))
            editing = false
        }
    }
    // MARK: - View

    /// expand normalized thumb to View coordinates and update outside model
    public func updateView() {
        menuSync?.setAny(named: nodeType.name, expanded)
    }
    public override func valueText() -> String {
        String(format: "%.2f", expanded)
    }
    public override func thumbOffset() -> CGSize {
        panelVm.axis == .vertical
        ? CGSize(width: 1, height: (1-thumb[0]) * panelVm.runway)
        : CGSize(width: thumb[0] * panelVm.runway, height: 1)
    }
}
