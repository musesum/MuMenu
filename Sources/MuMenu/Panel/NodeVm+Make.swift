//  created by musesum on 9/7/22.

import SwiftUI

extension NodeVm {

    static func makeNodeVm(_ menuTree: MenuTree,
                           _ branchVm: BranchVm,
                           _ prevNodeVm: NodeVm?,
                           icon: String = "") -> NodeVm {
        
        switch menuTree.nodeType {
        case .xy   : return LeafXyVm      (menuTree, branchVm, prevNodeVm)
        case .xyz  : return LeafXyzVm     (menuTree, branchVm, prevNodeVm)
        case .val  : return LeafValVm     (menuTree, branchVm, prevNodeVm)
        case .seg  : return LeafSegVm     (menuTree, branchVm, prevNodeVm)
        case .peer : return LeafPeerVm    (menuTree, branchVm, prevNodeVm)
        case .arch : return LeafArchiveVm (menuTree, branchVm, prevNodeVm)
        case .tog  : return LeafTogVm     (menuTree, branchVm, prevNodeVm)
        case .tap  : return LeafTapVm     (menuTree, branchVm, prevNodeVm)
        case .hand : return LeafHandVm    (menuTree, branchVm, prevNodeVm)
        default    : return NodeVm        (menuTree, branchVm, prevNodeVm)
        }
    }
}

extension NodeVm: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(nodeHash)
        _ = hasher.finalize()
        //print(path + String(format: ": %i", result))
    }
}
