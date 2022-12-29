//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Peer

    func followHashPath(_ treePath: [Int],
                        _ treeNow: Int) -> MuNodeVm? {

        var branchVm = branchVms.first
        var nodeNow: MuNodeVm?
        //??? log("followHashPath ", [" treeNow:", treeNow, " treePath: ", treePath])
        for treeHash in treePath {

            if let stepNodeVm = findNode(treeHash) {
                if stepNodeVm.node.hash == treeNow {
                    // nodeNow may be in middle of shown treePath
                    nodeNow = stepNodeVm
                }
                if !stepNodeVm.nodeType.isLeaf {
                    stepNodeVm.refreshBranch()
                }
                branchVm = stepNodeVm.nextBranchVm

                if branchVm == nil {
                    return nodeNow ?? stepNodeVm
                }
            }
        }
        return nil

        func findNode(_ treeHash: Int) -> MuNodeVm? {

            if let nodeVms = branchVm?.nodeVms {
                for nodeVm in nodeVms {
                    if nodeVm.node.hash == treeHash {
                        return nodeVm
                    }
                }
            }
            return nil
        }
    }

}
