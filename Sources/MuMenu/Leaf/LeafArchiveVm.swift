// created by musesum on 10/6/24

import SwiftUI
import MuPeer
import MuFlo

@MainActor
public class LeafArchiveVm: LeafVm {
    
    override public func touchLeaf(_: TouchState, _: Visitor) {}
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { ArchiveVm.shared.nameNow }
    override public func syncVal(_ : Visitor) {}
}
