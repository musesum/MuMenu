//  created by musesum on 12/14/22.

import Foundation

extension TreeVm { // + Peers

    func gotoNodeItem(_ nodeItem: MenuNodeItem) -> NodeVm? {
        let wordPath = nodeItem.wordPath
        let wordNow = nodeItem.wordNow
        return followWordPath(wordPath, wordNow)
    }
    func gotoLeafItem(_ leafItem: MenuLeafItem) -> LeafVm? {
        let wordPath = leafItem.wordPath
        let wordNow = leafItem.wordNow
        if let nodeVm = followWordPath(wordPath, wordNow),
           let leafVm = nodeVm as? LeafVm {
            return leafVm
        }
        return nil 
    }
    //..... not implemented
    func gotoOriginItem(_ originItem: MenuOriginItem) -> NodeVm? {
        let wordPath = originItem.wordPath
        let wordNow = originItem.wordNow
        return followWordPath(wordPath, wordNow)
    }
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
                    showTree(depth: 9, "wordPath", /*fromRemote*/ true)
                    return nodeNow ?? stepNodeVm
                }
            }
        }
        return nil

        func findNode(_ name: String) -> NodeVm? {
            if let nodeVms = branchVm?.nodeVms {
                for nodeVm in nodeVms {
                    if nodeVm.menuTree.flo.name == name {
                        return nodeVm
                    }
                }
            }
            return nil
        }
    }

}
