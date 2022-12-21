//  Created by warren on 12/10/21.

import SwiftUI

/// segmented control
public class MuLeafSegVm: MuLeafVm {

    var range: ClosedRange<Double> = 0...1

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leaves.append(self) // MuLeaf delegate for setting value
        
        refreshValue()
        updatePanelSizes()
    }

    /// normalize point to 0...1 based on defined range
    func normalizeTouch(_ point: CGPoint) -> Double {
        let v = panelVm.axis == .vertical ? point.y : point.x
        return panelVm.normalizeTouch(v: v)
    }
    
    /// scale up normalized to defined range
    var expanded: Double {
        scale(Double(nearestTick), from: 0...1, to: range)
    }

    lazy var count: CGFloat = {
        CGFloat(range.upperBound - range.lowerBound)
    }()


    /// adjust branch and panel sizes for smaller segments
    func updatePanelSizes() {
        let size = panelVm.axis == .vertical
        ? CGSize(width: 1, height: count.clamped(to: 2...4))
        : CGSize(width: count.clamped(to: 2...4), height: 1)

        branchVm.panelVm.aspectSz = size
        panelVm.aspectSz = size
        branchVm.show = true // refresh view
    }

    var nearestTick: CGFloat { return round(thumb[0]*count)/count }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
    lazy var ticks: [CGSize] = {

        var result = [CGSize]()
        let runway = panelVm.runway
        let radius = panelVm.thumbRadius
        let count = Float(range.upperBound - range.lowerBound)
        if count < 1 { return [] }
        let span = (1/max(1,count))
        let margin = Layout.radius - 2

        for v in stride(from: 0, through: Float(1), by: span) {

            let ofs = CGFloat(v) * runway + radius
            let size = panelVm.axis == .vertical
            ? CGSize(width: margin, height: ofs)
            : CGSize(width: ofs, height: margin)
            result.append (size)
        }
        return result
    }()

    /// normalized thumb radius
    lazy var thumbRadius: CGFloat = {
        Layout.diameter / max(runwayBounds.height,runwayBounds.width) / 2
    }()

    /// `touchBegin` inside thumb will Not move thumb.
    /// So, determing delta from center at touchState.begin
    var thumbBeginΔ = Double(0)
}

