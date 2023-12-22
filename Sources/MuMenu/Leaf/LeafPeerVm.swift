//  created by musesum on 12/5/22.


import SwiftUI
import MuPeer
import MuFlo

public class LeafPeerVm: LeafVm {
    
    public var peersVm = PeersVm.shared
    
    public init (_ node: FloNode,
                 _ branchVm: BranchVm,
                 _ prevVm: NodeVm?,
                 icon: String = "") {
        
        super.init(node, branchVm, prevVm)
        super.leafProto = self
        node.leafProtos.append(self)
    }
    override public func touchLeaf(_ : TouchState,
                                   _ : Visitor) {}
    func updateSync(_ visit: Visitor) {}
    
}

