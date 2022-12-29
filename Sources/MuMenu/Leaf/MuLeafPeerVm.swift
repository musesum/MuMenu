//  Created by warren on 12/5/22.


import SwiftUI
import Par

public class MuLeafPeerVm: MuLeafVm {

    var peersVm = PeersVm.shared

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self)
    }
    override public func touchLeaf(_ : MuTouchState,
                                   visitor: Visitor) {}
    func updateSync(_ visitor: Visitor) {}
    
}

