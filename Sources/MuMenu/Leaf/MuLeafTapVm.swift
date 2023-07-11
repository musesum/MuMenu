//  Created by warren on 5/10/22.

import SwiftUI
import MuVisit

public class MuLeafTapVm: MuLeafVm {

    init (_ node: MuFloNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) // MuLeaf delegate for setting value
        refreshValue(Visitor(.bind))
    }
    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: MuTouchState,
                                   _ visit: Visitor) {
        if !editing, touchState.phase == .began {

            editing = true
            thumbVal[0] = 1
            syncVal(visit)

        } else if touchState.phase.isDone() {

            editing = false
            thumbVal[0] = 0
            syncVal(visit)
        }
    }

}

