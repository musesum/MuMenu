//  created by musesum on 12/5/22.


import SwiftUI
import MuPeer
import MuFlo

public class LeafPeerVm: LeafVm {
    
    public var peersVm = PeersVm.shared
    
    public init (_ menuTree: MenuTree,
                 _ branchVm: BranchVm,
                 _ prevVm: NodeVm?,
                 icon: String = "") {
        
        super.init(menuTree, branchVm, prevVm)
    }
    override public func touchLeaf(_ : TouchState,
                                   _ : Visitor) {}

    override public func leafTitle() -> String { "Bonjour" }
}
