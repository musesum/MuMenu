//  created by musesum on 12/5/22.


import SwiftUI
import MuPeers
import MuFlo

public class LeafPeerVm: LeafVm {

    let peers: Peers
    override public func touchLeaf(_ : TouchState, _ : Visitor) {}
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { "\(peers.peerId)" }
    override public func syncVal(_ : Visitor) {}

    override init (_ menuTree: MenuTree,
                   _ branchVm: BranchVm,
                   _ prevVm: NodeVm?,
                   _ runTypes: [LeafRunwayType]) {

        self.peers = branchVm.treeVm.rootVm.peers
        super.init(menuTree, branchVm, prevVm, runTypes)
    }

}
