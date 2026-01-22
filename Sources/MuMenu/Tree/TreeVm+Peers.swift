//  created by musesum on 12/14/22.

import Foundation

extension TreeVm { // + Peers

    func followWordPath(_ wordPath: [String], _ wordNow: String) -> NodeVm? {
        var branchVm = branchVms.first
        var nodeNow: NodeVm?

        for name in wordPath {
            if let stepNodeVm = findNode(name) {
                if stepNodeVm.menuTree.flo.name == wordNow {
                    nodeNow = stepNodeVm
                }
                if !stepNodeVm.nodeType.isControl {
                    stepNodeVm.refreshBranch()
                }
                branchVm = stepNodeVm.nextBranchVm
                if branchVm == nil {
                    remoteTree()
                    let candidate = nodeNow ?? stepNodeVm
                    let isPrivate = candidate.menuTree.flo.policy.contains(.private)
                    return isPrivate ? nil : candidate
                }
            }
        }
        return nil

        func findNode(_ name: String) -> NodeVm? {
            if let nodeVms = branchVm?.nodeVms {
                for nodeVm in nodeVms {
                    let flo = nodeVm.menuTree.flo
                    if flo.name == name {
                        return nodeVm
                    }
                }
            }
            return nil
        }
    }

}
