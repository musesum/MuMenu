//  Created by warren on 12/5/22.


import SwiftUI

/// tap control
public class MuLeafPeerVm: MuLeafVm {

    var peersVm = PeersVm.shared

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leaves.append(self)

    }
}

