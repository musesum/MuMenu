//  created by musesum on 9/7/22.

import Foundation

var BranchCache = [Int: MuBranchVm]()

extension MuBranchVm {
    @discardableResult
    static func cached(nodes: [MuFloNode] = [],
                       treeVm: MuTreeVm,
                       branchPrev: MuBranchVm? = nil,
                       prevNodeVm: MuNodeVm? = nil,
                       zindex: CGFloat = 0) -> MuBranchVm {

        /// predict hash of next Branch
        var nextHash: Int {
            var hasher = Hasher()
            hasher.combine(prevNodeVm?.hashValue ?? 0)
            hasher.combine(treeVm.cornerAxis.corner.rawValue)
            hasher.combine(treeVm.cornerAxis.axis.rawValue)
            hasher.combine(MuBranchVm.titleForNodes(nodes))
            let hash = hasher.finalize()
            return hash
        }

        if let oldBranch = BranchCache[nextHash] {
            // print("🧺", terminator: " ")
            return oldBranch
        }
        let newBranch = MuBranchVm(nodes: nodes,
                                   treeVm: treeVm,
                                   branchPrev: branchPrev,
                                   prevNodeVm: prevNodeVm,
                                   zindex: zindex)

        BranchCache[nextHash] = newBranch

        return newBranch
    }
}

