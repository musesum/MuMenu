//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Peers

    func gotoNodeItem(_ nodeItem: MenuNodeItem) -> MuNodeVm? {
        let hashPath = nodeItem.hashPath
        let hashNow = nodeItem.hashNow
        return followHashPath(hashPath,hashNow)
    }
    func gotoLeafItem(_ leafItem: MenuLeafItem) -> MuLeafVm? {
        let hashPath = leafItem.hashPath
        let hashNow = leafItem.hashNow
        if let nodeVm = followHashPath(hashPath,hashNow),
           let leafVm = nodeVm as? MuLeafVm {
            return leafVm
        }
        return nil 
    }
    func followHashPath(_ hashPath: [Int],
                        _ hashNow: Int) -> MuNodeVm? {

        var branchVm = branchVms.first
        var nodeNow: MuNodeVm?

        for hashi in hashPath {

            if let stepNodeVm = findNode(hashi) {
                if stepNodeVm.node.hash == hashNow {
                    // nodeNow may be in middle of shown treePath
                    nodeNow = stepNodeVm
                }
                if !stepNodeVm.nodeType.isControl {
                    stepNodeVm.refreshBranch()
                }
                branchVm = stepNodeVm.nextBranchVm
                if branchVm == nil {
                    showTree("hash", /*fromRemote*/ true)
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
