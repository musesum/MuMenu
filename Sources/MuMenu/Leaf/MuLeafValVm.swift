//  Created by warren on 12/10/21.

import SwiftUI

/// 1d slider control
public class MuLeafValVm: MuLeafVm {

    var thumb = CGFloat(0)
    var range: ClosedRange<Float> = 0...1

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        node.proxies.append(self) // MuLeaf delegate for setting value
        refreshValue()
    }

    func normalizeNamed(_ name: String) -> CGFloat {
        let val = (nodeProto?.getAny(named: name) as? Float) ?? .zero
        let norm = scale(val, from: range, to: 0...1)
        return CGFloat(norm)
    }

    var expanded: Float {
        scale(Float(thumb), from: 0...1, to: range)
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


