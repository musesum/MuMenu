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
                                   _ visitor: Visitor) {
        if touchState.phase == .began {
            thumbNext[0] = 1
            editing = true
        } else if touchState.phase.isDone() {
            thumbNext[0] = 0
            editing = false
        }
        thumbNow = thumbNext
        syncNext(visitor)
        updateLeafPeers(visitor)
    }

}

