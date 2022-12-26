//  Created by warren on 12/10/21.

import SwiftUI

/// 1d slider control
public class MuLeafValVm: MuLeafVm {

    var range: ClosedRange<Double> = 0...1

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leaves.append(self) // MuLeaf delegate for setting value
        refreshValue()
    }

    func normalizeNamed(_ name: String) -> CGFloat {
        let val = (menuSync?.getAny(named: name) as? Double) ?? .zero
        let norm = scale(val, from: range, to: 0...1)
        return CGFloat(norm)
    }
    /// scale up normalized to defined range
    var expanded: Double {
        scale(thumb[0], from: 0...1, to: range)
    }
    func normalizeTouch(_ point: CGPoint) -> CGFloat {
        let v = panelVm.axis == .vertical ? point.y : point.x
        let vv = panelVm.normalizeTouch(v: v)
        return vv 
    }

    /// normalized thumb radius
    lazy var thumbRadius: CGFloat = {
        Layout.diameter / max(runwayBounds.height,runwayBounds.width) / 2
    }()

    /// `touchBegin` inside thumb will Not move thumb.
    /// So, determing delta from center at touchState.begin
    var thumbBeginΔ = CGFloat.zero
}


