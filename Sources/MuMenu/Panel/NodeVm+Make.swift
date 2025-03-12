//  created by musesum on 9/7/22.

import SwiftUI

extension NodeVm {

    static func makeNodeVm(_ menuTree: MenuTree,
                           _ branchVm: BranchVm,
                           _ prevVm: NodeVm?) -> NodeVm {
        let m = menuTree
        let b = branchVm
        let p = prevVm
        
        switch menuTree.nodeType { //              __________ runways _________
        case .xy   : return LeafXyVm      (m,b,p, [.runX, .runY, .runXY])
        case .xyz  : return LeafXyzVm     (m,b,p, [.runX, .runY, .runZ, .runXY])
        case .val  : return LeafValVm     (m,b,p, [.runVal])
        case .seg  : return LeafSegVm     (m,b,p, [.runVal])
        case .tog  : return LeafTogVm     (m,b,p, [.none])
        case .hand : return LeafHandVm    (m,b,p, [.runX, .runY, .runZ, .runXY])
        case .peer : return LeafPeerVm    (m,b,p, [])
        case .arch : return LeafArchiveVm (m,b,p, [])
        default    : return NodeVm        (m,b,p)
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
