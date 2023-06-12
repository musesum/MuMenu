//  Created by warren on 5/10/22.

import SwiftUI
import MuPar

/// toggle control
public class MuLeafTogVm: MuLeafVm {

    init (_ node: MuFloNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) 
        refreshValue(Visitor(.model))
    }
    override public func touchLeaf(_ touchState: MuTouchState,
                                   _ visit: Visitor) {
        if !editing, touchState.phase == .began  {
            editing = true
            thumbNext[0] = (thumbNext[0] == 1.0 ? 0 : 1)
            syncNext(visit)
            updateLeafPeers(visit)
        } else if editing, touchState.phase.isDone() {
            editing = false
            refreshView()
        }
    }

}

