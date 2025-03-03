//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// 1d slider control
public class LeafValVm: LeafVm {

    var range: ClosedRange<Double> = 0...1

    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {
        
        super.init(menuTree, branchVm, prevVm)

        setRanges()
        let visit = Visitor(0, .bind)
        updateFromFlo(menuTree.model˚, visit)
        syncVal(visit)
    }
    /// normalize to and from scalar range
    func setRanges() {
        if let exprs = menuTree.model˚.exprs {
            if let x = exprs.nameAny["x"] as? Scalar {
                range = x.range()
            } else if let y = exprs.nameAny["y"] as? Scalar {
                range = y.range()
            } else if let scalar = exprs.nameAny.values.first as? Scalar {
                range = scalar.range()
            }
        }
    }

    /// scale up normalized to defined range
    var expanded: Double {
        guard let thumb = runways.thumb() else { return 0 }
        return scale(thumb.value.x, from: 0...1, to: range)
    }
  

    /// `touchBegin` inside thumb will Not move thumb.
    /// So, determing delta from center at touchState.begin
    var thumbBeginΔ = CGFloat.zero


    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {

        editing = runways.touchLeaf(touchState)
        syncVal(visit)
    }
    /// user double tapped a parent node
    override func tapLeaf() {
        resetOrigin()
    }
    override public func leafTitle() -> String { String(format: "%.2f", expanded) }

}


