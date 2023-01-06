//  Created by warren on 5/10/22.

import SwiftUI
import Par

/// toggle control
public class MuLeafTogVm: MuLeafVm {

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) 
        refreshValue()
    }
    override public func touchLeaf(_ touchState: MuTouchState,
                                   visitor: Visitor = Visitor()) {
        if !editing, touchState.phase == .began  {
            thumb[0] = (thumb[0]==1.0 ? 0 : 1)
            editing = true
        } else if editing, touchState.phase.isDone() {
            editing = false
        }
        updateSync(visitor)
    }

    func updateSync(_ visitor: Visitor) {

        if let menuSync, menuSync.setAny(named: nodeType.name, thumb[0], visitor) {
            
            updateLeafPeers(visitor)
        }
    }

}

