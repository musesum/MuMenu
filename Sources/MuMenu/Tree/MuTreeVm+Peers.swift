//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Peers

    func followHashPath(_ menuItem: MenuNodeItem) -> MuNodeVm? {

        let hashPath = menuItem.hashPath
        let hashNow = menuItem.hashNow
        var branchVm = branchVms.first
        var nodeNow: MuNodeVm?

        for hashi in hashPath {

            if let stepNodeVm = findNode(hashi) {
                if stepNodeVm.node.hash == hashNow {
                    // nodeNow may be in middle of shown treePath
                    nodeNow = stepNodeVm
                }
                if !stepNodeVm.nodeType.isLeaf {
                    stepNodeVm.refreshBranch()
                    showTree("hash", /*fromRemote*/ true)
                }
                branchVm = stepNodeVm.nextBranchVm
                if branchVm == nil {
                    return nodeNow ?? stepNodeVm
                }
            }
        }
        return nil


        func findNode(_ hashi: Int) -> MuNodeVm? {

            if let nodeVms = branchVm?.nodeVms {
                for nodeVm in nodeVms {
                    if nodeVm.node.hash == hashi {
                        return nodeVm
                    }
                }
            }
            return nil
        }
    }

}
