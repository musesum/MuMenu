//  created by musesum on 9/7/22.

import Foundation
import MuFlo
var BranchCache = [Int: BranchVm]()

extension BranchVm {
    @discardableResult
    static func cached(menuTrees: [MenuTree] = [],
                       treeVm: TreeVm,
                       branchPrev: BranchVm? = nil,
                       prevNodeVm: NodeVm? = nil,
                       zindex: CGFloat = 0) -> BranchVm {

        /// predict hash of next Branch
        var nextHash: (Int, BranchVm?) {
            var hasher = Hasher()
            let prevHash = prevNodeVm?.hashValue ?? 0
            let menuOpHash = treeVm.trunk.menuOp.rawValue
            let title = BranchVm.titleForNodes(menuTrees)

            hasher.combine(prevHash)
            hasher.combine(menuOpHash)
            hasher.combine(title)
            let hash = hasher.finalize()
            let oldBranch = BranchCache[hash]

            //PrintLog("*** prevHash: \(prevHash), cornerHash: \(cornerHash), axisHash: \(axisHash), title: \(title), hash: \(hash) old \(oldBranch == nil ? "_" : "🧺")")
            return (hash,oldBranch)
        }

        let (hash,oldBranch) = nextHash
        if let oldBranch {
            return oldBranch
        }

        let newBranch = BranchVm(menuTrees: menuTrees,
                                 treeVm: treeVm,
                                 branchPrev: branchPrev,
                                 prevNodeVm: prevNodeVm,
                                 zindex: zindex)

        BranchCache[hash] = newBranch

        return newBranch
    }
}

