//  Created by warren on 5/10/22.

import SwiftUI
import Par // Visitor

public class MuLeafTapVm: MuLeafVm {

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self) // MuLeaf delegate for setting value
        refreshValue()
    }
    override public func touchLeaf(_ touchState: MuTouchState,
                                   visitor: Visitor = Visitor()) {
        if touchState.phase == .began {
            thumb[0] = 1
            editing = true
        } else if touchState.phase.isDone() {
            thumb[0] = 0
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

