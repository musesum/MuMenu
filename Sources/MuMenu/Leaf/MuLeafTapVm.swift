//  Created by warren on 5/10/22.

import SwiftUI

/// tap control
public class MuLeafTapVm: MuLeafVm {

    var thumb = CGFloat.zero

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        node.proxies.append(self) // MuLeaf delegate for setting value
        refreshValue()
    }
}
