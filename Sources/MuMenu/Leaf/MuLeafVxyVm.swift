//  Created by warren on 5/10/22.

import SwiftUI
import Par

/// 2d XY control
public class MuLeafVxyVm: MuLeafVm {
    
    var ranges = [String : ClosedRange<Double>]()

    override init (_ node: MuNode,
                   _ branchVm: MuBranchVm,
                   _ prevVm: MuNodeVm?) {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self)  //MuLeafProtocol for exchanging value
        refreshValue()
    }
    func normalizeNamed(_ name: String,
                        _ range: ClosedRange<Double>?) -> Double {
        
        let val = (menuSync?.getAny(named: name) as? Double) ?? .zero
        let norm = scale(val, from: range ?? 0...1, to: 0...1)
        return norm
    }
    func expand(named: String, _ value: CGFloat) -> Double {

        let range = ranges[named] ?? 0...1
        let result = scale(Double(value), from: 0...1, to: range)
        return result
    }

    /// Tick marks for double touch alignments
    /// shown at center, corner, and sides.
    /// So: NW, N, NE, E, SE, S, SW, W, Center
    var nearestTick: CGPoint {
        CGPoint(x: round(thumb[0] * 2) / 2,
                y: round(thumb[1] * 2) / 2)
    }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
    lazy var ticks: [CGSize] = {
        var result = [CGSize]()
        let runway = self.panelVm.runwayXY
        let radius = self.panelVm.thumbRadius
        let span = CGFloat(0.5)
        let margin = Layout.radius - 2
        for w in stride(from: CGFloat(0), through: 1, by: span) {
            for h in stride(from: CGFloat(0), through: 1, by: span) {

                let tick = CGSize(width:  w * runway.x,
                                  height: h * runway.y)
                result.append(tick)
            }
        }
        return result
    }()

    /// normalized thumb radius
    lazy var thumbRadius: CGFloat = {
        Layout.diameter / max(runwayBounds.height,runwayBounds.width) / 2
    }()

    /// `touchBegin` inside thumb will probably be off-center.
    /// To avoid a sudden jump, thumbBeginΔ adds an offset.
    var thumbBeginΔ = [Double](repeatElement(0, count: 2))

    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: MuTouchState,
                                   visitor: Visitor = Visitor()) {

        if visitor.newVisit(hash) {
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
            updateSync(visitor)
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
    /// called via user touch or via model update
    func updateSync(_ visitor: Visitor) {

        let x = expand(named: "x", thumb[0])
        let y = expand(named: "y", thumb[1])
        if let menuSync, menuSync.setAnys([("x", x),("y", y)], visitor) {
            updateLeafPeers(visitor)
        }
        branchVm.show = branchVm.show
    }
    
}
