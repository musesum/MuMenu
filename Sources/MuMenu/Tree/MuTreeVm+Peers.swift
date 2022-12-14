//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Peer


    func followHashPath(_ hashPath: [Int]) {
return 
        log("from ", [hashPath])

        var branchVm = branchVms.first

        for hash in hashPath {

            print("\(hash)", terminator: ": ")
            if let foundNodeVm = findNode(hash) {
                print("  found: \"\(foundNodeVm.node.title)\"")
                foundNodeVm.refreshBranch()
                branchVm = foundNodeVm.nextBranchVm
                if branchVm == nil {
                    print("*** done")
                    return
                }
            } else {
                print(" not found")
            }

        }

        func findNode(_ hash: Int) -> MuNodeVm? {

            if let nodeVms = branchVm?.nodeVms {

                print("  ")
                for nodeVm in nodeVms {
                    print("\"\(nodeVm.node.title)\"", terminator: ", ")
                    let nodeHash = nodeVm.node.hash
                    if nodeHash == hash {
                        return nodeVm
                    }
                }
            }
            return nil
        }
    }

}
