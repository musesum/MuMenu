//  created by musesum on 9/7/22.

import SwiftUI

extension NodeVm {

    static func cached(_ node: FloNode,
                       _ branchVm: BranchVm,
                       _ prevNodeVm: NodeVm?,
                       icon: String = "") -> NodeVm {

        switch node.nodeType {
        case .xy   : return LeafXyVm   (node, branchVm, prevNodeVm)
        case .xyz  : return LeafXyzVm  (node, branchVm, prevNodeVm)
        case .val  : return LeafValVm  (node, branchVm, prevNodeVm)
        case .seg  : return LeafSegVm  (node, branchVm, prevNodeVm)
        case .peer : return LeafPeerVm (node, branchVm, prevNodeVm)
        case .tog  : return LeafTogVm  (node, branchVm, prevNodeVm)
        case .tap  : return LeafTapVm  (node, branchVm, prevNodeVm)
        case .hand : return LeafHandVm (node, branchVm, prevNodeVm)
        default    : return NodeVm     (node, branchVm, prevNodeVm)
        }
    }
}

extension NodeVm: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
        _ = hasher.finalize()
        //print(path + String(format: ": %i", result))
    }
}
