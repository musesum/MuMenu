//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// segmented control
public class LeafSegVm: LeafVm {

    var range: ClosedRange<Double> = 0...1

    init (_ node: FloNode,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) // MuLeaf delegate for setting value

        setRanges()

        refreshValue(Visitor(.bind))
        updatePanelSizes()
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

    /// normalize point to 0...1 based on defined range
    func normalizeTouch(_ point: CGPoint) -> Double {
        let v = panelVm.isVertical ? point.y : point.x
        return panelVm.normalizeTouch(v: v)
    }
    

    lazy var count: Double = {
        range.upperBound - range.lowerBound
    }()


    /// adjust branch and panel sizes for smaller segments
    func updatePanelSizes() {
        let size = panelVm.isVertical
        ? CGSize(width: 1, height: count.clamped(to: 2...4))
        : CGSize(width: count.clamped(to: 2...4), height: 1)

        branchVm.panelVm.aspectSz = size
        panelVm.aspectSz = size
    }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
    func ticks() -> [CGSize] {

        var result = [CGSize]()
        let runway = panelVm.runway(.xy)
        let radius = panelVm.thumbRadius
        let count = Float(range.upperBound - range.lowerBound)
        if count < 1 { return [] }
        let span = (1/max(1,count))
        let margin = Layout.radius - 2

        for v in stride(from: 0, through: Float(1), by: span) {

            let ofs = CGFloat(v) * runway + radius
            let size = panelVm.isVertical
            ? CGSize(width: margin, height: ofs)
            : CGSize(width: ofs, height: margin)
            result.append (size)
        }
        return result
    }

    /// `touchBegin` inside thumb will Not move thumb.
    /// So, determing delta from center at touchState.begin
    var thumbBeginΔ = Double(0)


    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {

        if touchState.phase == .began {
            touchThumbBegin()
            editing = true
        } else if !touchState.phase.isDone() {
            touchThumbNext()
            editing = true
        } else {
            editing = false
        }
        syncVal(visit)

        func touchThumbBegin() {
            guard let runwayBounds = runway(.xy) else { return }
            let thumbPrev = thumbVal[0]
            let touchDelta = touchState.pointNow - runwayBounds.origin
            let thumbDelta = normalizeTouch(touchDelta)
            let touchedInsideThumb = abs(thumbDelta.distance(to: thumbPrev)) < thumbNormRadius()
            thumbBeginΔ = touchedInsideThumb ? thumbPrev - thumbDelta : .zero
            thumbVal[0] = thumbDelta + thumbBeginΔ
        }
        /// user touched control, translate to normalized thumb (0...1)
        func touchThumbNext() {
            guard let runwayBounds = runway(.xy) else { return }
            if !runwayBounds.contains(touchState.pointNow) {
                // slowly erode thumbBegin∆ when out of bounds
                thumbBeginΔ = thumbBeginΔ * 0.85
            }
            let touchDelta = touchState.pointNow - runwayBounds.origin
            thumbVal[0] = normalizeTouch(touchDelta) + thumbBeginΔ
        }
    }
}

