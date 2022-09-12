//  Created by warren on 5/10/22.

import SwiftUI

/// toggle control
public class MuLeafTogVm: MuLeafVm {

    var thumb = CGFloat(0)

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm?,
          icon: String = "") {

        super.init(node, branchVm, prevVm) 
        node.proxies.append(self) 
        refreshValue()
    }
}

