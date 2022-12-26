//  Created by warren on 9/10/22.

import SwiftUI
import Par

extension MuLeafVxyVm: MuLeafProtocol {

    /// user touch gesture inside runway
    public func touchLeaf(_ touchState: MuTouchState) {

        if touchState.phase == .began {
            if touchState.touchBeginCount == 1 {
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
        updateSync(Visitor())

        func tapThumb() {
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbPrior = panelVm.normalizeTouch(xy: touchDelta)
            thumb = quantizeThumb(thumbPrior)

            let x = thumb[0] - thumbPrior[0]
            let y = thumb[1] - thumbPrior[1]
            thumbBeginΔ = [x, y]
        }

        func touchThumbBegin() {
            let thumbPrev = thumb
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbNext = panelVm.normalizeTouch(xy: touchDelta)
            let distance = thumbNext.distance(thumbPrev)
            let touchedInsideThumb = distance < thumbRadius
            thumbBeginΔ = (touchedInsideThumb
                           ? (thumbPrev - thumbNext)
                           : [0,0])

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
        func quantizeThumb(_ point: [Double]) -> [Double] {

            let x = round(point[0] * 2) / 2
            let y = round(point[1] * 2) / 2
            return [x,y]
        }
    }
    // MARK: - Value

    public func refreshValue() {
        if let nameRanges = menuSync?.getRanges(named: ["x","y"]) {
            for (name,range) in nameRanges {
                ranges[name] = range
            }
        }
        let xx = normalizeNamed("x",ranges["x"])
        let yy = normalizeNamed("y",ranges["y"])
        thumb = [xx,yy]
    }

    /// update from model - not touch
    public func updateLeaf(_ any: Any, _ visitor: Visitor) {
        visitor.startVisit(hash, visit)
        func visit() {
            editing = true
            if let v = any as? [Double], v.count == 2 {
                    thumb = [v[0],v[1]]
            } else {
                print("⁉️ unknown upddate type")
            }
            editing = false
            updateSync(visitor)
        }
    }

    private func updateSync(_ visitor: Visitor) {
        
        let x = expand(named: "x", thumb[0])
        let y = expand(named: "y", thumb[1])
        menuSync?.setAnys([("x", x),("y", y)], visitor)
        updatePeers(visitor)
    }

    public func valueText() -> String {
        String(format: "x %.2f y %.2f",
               expand(named: "x", thumb[0]),
               expand(named: "y", thumb[1]))
    }

    public func thumbOffset() -> CGSize {
        CGSize(width:     thumb[0]  * panelVm.runway,
               height: (1-thumb[1]) * panelVm.runway)
    }

}
