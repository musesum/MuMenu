//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// toggle control
public class LeafTogVm: LeafVm {

    init (_ node: FloNode,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) 
        refreshValue(Visitor(.bind))
    }
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {
        if !editing, touchState.phase == .began  {

            editing = true
            thumbVal.x = (thumbVal.x == 1.0 ? 0 : 1)
            syncVal(visit)
            
        } else if editing, touchState.phase.isDone() {

            editing = false
            syncVal(visit)
        }
    }

}

