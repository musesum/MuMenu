//  created by musesum on 12/5/22.


import SwiftUI
import MuPeer
import MuFlo

public class LeafPeerVm: LeafVm {
    
    public var peersVm = PeersVm()

    override public func touchLeaf(_ : TouchState, _ : Visitor) {}
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { "Peers" }
    override public func syncVal(_ : Visitor) {}
}
