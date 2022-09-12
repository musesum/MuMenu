//
//  File.swift
//  
//
//  Created by warren on 9/10/22.
//

import Foundation

extension MuLeafValVm: MuLeafProtocol {

    /// user touch gesture inside runway
    public func touchLeaf(_ touchState: MuTouchState) {

        if touchState.phase == .begin {
            touchThumbBegin()
            updateView()
            editing = true
        } else if touchState.phase != .ended {
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
            thumb = normalizeTouch(touchDelta) + thumbBeginΔ
        }
        func touchThumbBegin() {
            let thumbPrev = thumb
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbNext = normalizeTouch(touchDelta)
            let touchedInsideThumb = abs(thumbNext.distance(to: thumbPrev)) < thumbRadius
            thumbBeginΔ = touchedInsideThumb ? thumbPrev - thumbNext : .zero
            thumb = thumbNext + thumbBeginΔ
        }
    }
    
    // MARK: - Value

    public override func refreshValue() {
        thumb = normalizeNamed(nodeType.name)
        range = nodeProto?.getRange(named: nodeType.name) ?? 0...1
    }

    public func updateLeaf(_ any: Any) {
        if let v = any as? Float {
            editing = true
            thumb = CGFloat(scale(v, from: range, to: 0...1))
            editing = false
        }
    }
    // MARK: - View

    /// expand normalized thumb to View coordinates and update outside model
    public func updateView() {
        nodeProto?.setAny(named: nodeType.name, expanded)
    }
    public override func valueText() -> String {
        String(format: "%.2f", expanded)
    }
    public override func thumbOffset() -> CGSize {
        panelVm.axis == .vertical
        ? CGSize(width: 1, height: (1-thumb) * panelVm.runway)
        : CGSize(width: thumb * panelVm.runway, height: 1)
    }
}
