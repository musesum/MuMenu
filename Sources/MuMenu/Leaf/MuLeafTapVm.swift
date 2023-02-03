//  Created by warren on 5/10/22.

import SwiftUI
import MuPar // Visitor

public class MuLeafTapVm: MuLeafVm {

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) // MuLeaf delegate for setting value
        refreshValue(Visitor(.model))
    }
    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: MuTouchState,
                                   _ visit: Visitor) {
        if touchState.phase == .began {
            editing = true
            thumbNext[0] = 1
            syncNext(visit)
            updateLeafPeers(visit)
        } else if touchState.phase.isDone() {
            thumbNext[0] = 0
            syncNext(visit)
            updateLeafPeers(visit)
            editing = false
        }

    }

}

