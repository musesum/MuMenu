//  Created by warren on 9/10/22.

import SwiftUI

extension MuLeafVxyVm: MuLeafProtocol {

    /// user touch gesture inside runway
    public func touchLeaf(_ touchState: MuTouchState) {

        if touchState.phase == .begin {

            if touchState.touchBeginCount == 1 {
                tapThumb()
                updateView()
                editing = true
            } else {
                touchThumbBegin()
                updateView()
                editing = true
            }
        } else if touchState.phase != .ended {
            touchThumbNext()
            updateView()
            editing = true
        } else {
            editing = false
        }

        func tapThumb() {
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbPrior = panelVm.normalizeTouch(xy: touchDelta)
            thumb = quantizeThumb(thumbPrior)
            thumbBeginΔ = thumb - thumbPrior
        }

        func touchThumbBegin() {
            let thumbPrev = thumb
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbNext = panelVm.normalizeTouch(xy: touchDelta)
            let touchedInsideThumb = thumbNext.distance(thumbPrev) < thumbRadius
            thumbBeginΔ = touchedInsideThumb ? thumbPrev - thumbNext : .zero
            thumb = thumbNext + thumbBeginΔ
        }

        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            if !runwayBounds.contains(touchState.pointNow) {
                // slowly erode thumbBegin∆ when out of bounds
                thumbBeginΔ = thumbBeginΔ * 0.85
            }
            let touchDelta = touchState.pointNow - runwayBounds.origin
            thumb = panelVm.normalizeTouch(xy: touchDelta) + thumbBeginΔ
        }
        /// double touch will align thumb to center, corners or sides.
        func quantizeThumb(_ point: CGPoint) -> CGPoint {
            let x = round(point.x * 2) / 2
            let y = round(point.y * 2) / 2
            return CGPoint(x: x, y: y)
        }
    }
    // MARK: - Value

    public override func refreshValue() {
        if let nameRanges = nodeProto?.getRanges(named: ["x","y"]) {
            for (name,range) in nameRanges {
                ranges[name] = range
            }
        }
        let x = normalizeNamed("x",ranges["x"])
        let y = normalizeNamed("y",ranges["y"])
        thumb = CGPoint(x: x, y: y)
    }

    /// update from model - not touch
    public func updateLeaf(_ any: Any) {
        if let p = any as? CGPoint {
            editing = true
            let x = scale(Float(p.x), from: ranges["x"] ?? 0...1, to: 0...1)
            let y = scale(Float(p.y), from: ranges["y"] ?? 0...1, to: 0...1)
            thumb = CGPoint(x: CGFloat(x), y: CGFloat(y))
            editing = false
        }
    }

    // MARK: - View

    /// expand normalized thumb to View coordinates and update outside model
    public func updateView() {
        let x = expand(named: "x", thumb.x)
        let y = expand(named: "y", thumb.y)
        nodeProto?.setAnys([("x", x),("y", y)])
    }
    public override func valueText() -> String {
        String(format: "x %.2f y %.2f",
               expand(named: "x", thumb.x),
               expand(named: "y", thumb.y))
    }
    public override func thumbOffset() -> CGSize {
        CGSize(width:  thumb.x * panelVm.runway,
               height: (1-thumb.y) * panelVm.runway)
    }

}
