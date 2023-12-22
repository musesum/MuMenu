//  created by musesum on 12/14/22.

import Foundation

extension TreeVm { // + Peers

    func gotoNodeItem(_ nodeItem: MenuNodeItem) -> NodeVm? {
        let hashPath = nodeItem.hashPath
        let hashNow = nodeItem.hashNow
        return followHashPath(hashPath,hashNow)
    }
    func gotoLeafItem(_ leafItem: MenuLeafItem) -> LeafVm? {
        let hashPath = leafItem.hashPath
        let hashNow = leafItem.hashNow
        if let nodeVm = followHashPath(hashPath,hashNow),
           let leafVm = nodeVm as? LeafVm {
            return leafVm
        }
        return nil 
    }
    func followHashPath(_ hashPath: [Int],
                        _ hashNow: Int) -> NodeVm? {

        var branchVm = branchVms.first
        var nodeNow: NodeVm?

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


        func findNode(_ hashi: Int) -> NodeVm? {

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
