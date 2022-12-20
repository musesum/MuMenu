//  Created by warren on 5/10/22.

import SwiftUI

/// toggle control
public class MuLeafTogVm: MuLeafVm {

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm) 
        node.leaves.append(self) 
        refreshValue()
    }
}

