//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

public class LeafTapVm: LeafVm {

    init (_ node: FloNode,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) // MuLeaf delegate for setting value
        refreshValue(Visitor(.bind))
    }
    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
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

