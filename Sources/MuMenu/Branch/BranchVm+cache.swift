//  created by musesum on 9/7/22.

import Foundation

var BranchCache = [Int: BranchVm]()

extension BranchVm {
    @discardableResult
    static func cached(nodes: [FloNode] = [],
                       treeVm: TreeVm,
                       branchPrev: BranchVm? = nil,
                       prevNodeVm: NodeVm? = nil,
                       zindex: CGFloat = 0) -> BranchVm {

        /// predict hash of next Branch
        var nextHash: Int {
            var hasher = Hasher()
            hasher.combine(prevNodeVm?.hashValue ?? 0)
            hasher.combine(treeVm.cornerItem.corner.rawValue)
            hasher.combine(treeVm.cornerItem.axis.rawValue)
            hasher.combine(BranchVm.titleForNodes(nodes))
            let hash = hasher.finalize()
            return hash
        }

        if let oldBranch = BranchCache[nextHash] {
            // print("🧺", terminator: " ")
            return oldBranch
        }
        let newBranch = BranchVm(nodes: nodes,
                                   treeVm: treeVm,
                                   branchPrev: branchPrev,
                                   prevNodeVm: prevNodeVm,
                                   zindex: zindex)

        BranchCache[nextHash] = newBranch

        return newBranch
    }
}

