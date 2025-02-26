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
        super.leafProto = self
        menuTree.leafProto = self
    }
    override public func touchLeaf(_ : TouchState,
                                   _ : Visitor) {}

    func updateSync(_ visit: Visitor) {}
}

extension LeafPeerVm: LeafProtocol {

    public func refreshValue(_ _: Visitor) {}
    public func refreshPeers(_ _: Visitor) {}
    public func remoteValTween(_ _: ValTween, _ _: Visitor) {}
    public func updateFromModel(_ _: Flo, _ _: Visitor) {}
    public func leafTitle() -> String { "Bonjour" }
    public func treeTitle() -> String { "" }
    public func thumbValueOffset(_:Runway) -> CGSize {  CGSize(width: 0, height:  panelVm.runLength(.none)) }
    public func thumbTweenOffset(_:Runway) -> CGSize {  CGSize(width: 0, height:  panelVm.runLength(.none)) }
    public func syncVal(_ _: Visitor) {}
}
