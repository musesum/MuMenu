//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Peer

    func followHashPath(_ treeHashPath: [Int],
                        _ treeNowHash: Int) -> MuNodeVm? {

        var branchVm = branchVms.first
        var nodeNow: MuNodeVm?

        for hash in treeHashPath {
            
            logPath("\(hash)", ": ")
            if let stepNode = findNode(hash) {
                let stepHash = stepNode.node.hash
                if stepHash == treeNowHash {
                    nodeNow = stepNode
                }
                logPath("  found: \"\(stepNode.node.title)\"")
                if !stepNode.nodeType.isLeaf {
                    stepNode.refreshBranch()
                }
                branchVm = stepNode.nextBranchVm
                if branchVm == nil {
                    logPath(" done: \(stepNode.node.title)")
                    return nodeNow ?? stepNode
                }
            } else {
                logPath(" not found")
            }

        }
        return nil

        func findNode(_ hash: Int) -> MuNodeVm? {

            if let nodeVms = branchVm?.nodeVms {

                logPath("  ")
                for nodeVm in nodeVms {
                    logPath("\"\(nodeVm.node.title)\"", ", ")
                    let nodeHash = nodeVm.node.hash
                    if nodeHash == hash {
                        return nodeVm
                    }
                }
            }
            return nil
        }
        func logPath(_ s: String,_  t: String = "\n" ) {
            //print(s, terminator: t)
        }
    }

}
