//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

public class LeafTapVm: LeafVm {

    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {
        
        super.init(menuTree, branchVm, prevVm)
        super.leafProto = self
        menuTree.leafProto = self // MuLeaf delegate for setting value
        refreshValue(Visitor(0, .bind))
    }
    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {
        updateRunway(touchState.pointNow)
        if !editing, touchState.phase == .began {

            editing = true
            thumb.value.x = 1
            syncVal(visit)

        } else if touchState.phase.done {

            editing = false
            thumb.value.x = 0
            syncVal(visit)
        }
    }
    /// user double tapped a parent node
    override func tapLeaf() {
        resetOrigin()
    }

}

