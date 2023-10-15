//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// toggle control
public class MuLeafTogVm: MuLeafVm {

    init (_ node: MuFloNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) 
        refreshValue(Visitor(.bind))
    }
    override public func touchLeaf(_ touchState: MuTouchState,
                                   _ visit: Visitor) {
        if !editing, touchState.phase == .began  {

            editing = true
            thumbVal[0] = (thumbVal[0] == 1.0 ? 0 : 1)
            syncVal(visit)
            
        } else if editing, touchState.phase.isDone() {

            editing = false
            syncVal(visit)
        }
    }

}

