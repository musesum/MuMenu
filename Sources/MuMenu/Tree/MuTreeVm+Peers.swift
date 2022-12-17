//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Peer

    func followHashPath(_ hashPath: [Int]) -> MuNodeVm? {
        var branchVm = branchVms.first

        for hash in hashPath {

            logPath("\(hash)", ": ")
            if let foundNodeVm = findNode(hash) {
                logPath("  found: \"\(foundNodeVm.node.title)\"")
                foundNodeVm.refreshBranch()
                branchVm = foundNodeVm.nextBranchVm
                if branchVm == nil {
                    logPath("*** done")
                    return foundNodeVm
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
