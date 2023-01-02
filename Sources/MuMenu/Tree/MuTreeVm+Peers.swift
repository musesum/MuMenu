//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Peers

    func followHashPath(_ menuItem: TouchMenuItem) -> MuNodeVm? {

        let menuType = MuMenuType(menuItem.type)
        let treePath = menuItem.hashPath
        let treeNow = menuItem.hashNow
        let startIndex = menuItem.startIndex

        var branchVm = branchVms.first
        var nodeNow: MuNodeVm?

        log("followHashPath ", [
            " type:", menuItem.type,
            " startIndex:",startIndex,
            " treeNow:", treeNow,
            " treePath: ", treePath])

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
                    return finalize(nodeNow ?? stepNodeVm)
                }
            }
        }
        return nil

        func finalize(_ nodeVm: MuNodeVm) -> MuNodeVm? {
            if menuType == .tree {
                shiftTree(to: startIndex)
            }
            return nodeVm
        }

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
