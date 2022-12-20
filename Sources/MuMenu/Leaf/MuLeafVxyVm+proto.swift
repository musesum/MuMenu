//  Created by warren on 9/10/22.

import SwiftUI

extension MuLeafVxyVm: MuLeafProtocol {

    /// user touch gesture inside runway
    public func touchLeaf(_ touchState: MuTouchState) {

        if touchState.phase == .began {

            if touchState.touchBeginCount == 1 {
                tapThumb()
                updateSync()
                updatePeers()
                editing = true
            } else {
                touchThumbBegin()
                updateSync()
                updatePeers()
                editing = true
            }
        } else if !touchState.phase.isDone() {
            touchThumbNext()
            updateSync()
            updatePeers()
            editing = true
        } else {
            editing = false
        }

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
            thumbBeginΔ = touchedInsideThumb ? thumbPrev - thumbNext : [0,0]
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

    public override func refreshValue() {
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
    public override func updateLeaf(_ any: Any) {
        switch any {
            case let v as [Double]:
                updateThumb(v[0], v[1])

            case let v as [String: Double]:

                if let x = v["x"],
                   let y = v["y"] {
                    updateThumb(x,y)
                }
            case let v as CGPoint:
                updateThumb(Double(v.x), Double(v.y))

            default:
                print("⁉️ unknown upddate type")
        }
        func updateThumb(_ x: Double, _ y: Double) {

            editing = true
            let xx = scale(x, from: ranges["x"] ?? 0...1, to: 0...1)
            let yy = scale(y, from: ranges["y"] ?? 0...1, to: 0...1)
            thumb = [xx,yy]
            editing = false
        }

    }

    // MARK: - View

    /// expand normalized thumb to View coordinates and update outside model
    public override func updateSync() {
        let x = expand(named: "x", thumb[0])
        let y = expand(named: "y", thumb[1])
        menuSync?.setAnys([("x", x),("y", y)])
    }
    public override func valueText() -> String {
        String(format: "x %.2f y %.2f",
               expand(named: "x", thumb[0]),
               expand(named: "y", thumb[1]))
    }
    public override func thumbOffset() -> CGSize {
        CGSize(width:  thumb[0] * panelVm.runway,
               height: (1-thumb[1]) * panelVm.runway)
    }

}
