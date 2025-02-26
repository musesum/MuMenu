//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// toggle control
public class LeafTogVm: LeafVm {

    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {

        super.init(menuTree, branchVm, prevVm)
        super.leafProto = self
        menuTree.leafProto = self 
        refreshValue(Visitor(0, .bind))
    }
    /// user touched leaf 
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {
        updateRunway(touchState.pointNow)
        if touchState.phase == .ended,
           touchState.touchEndedCount == 1  {

            thumb.value.x = (thumb.value.x == 1.0 ? 0 : 1)
            syncVal(visit)
        }
    }

    /// user double tapped a parent node
    override func tapLeaf() {
        thumb.value.x = (thumb.value.x == 1.0 ? 0 : 1)
        syncVal(Visitor(0,.user))
    }


}

