// created by musesum on 10/6/24

import SwiftUI
import MuPeer
import MuFlo

public class LeafArchiveVm: LeafVm {

    public init (_ menuTree: MenuTree,
                 _ branchVm: BranchVm,
                 _ prevVm: NodeVm?,
                 icon: String = "") {

        super.init(menuTree, branchVm, prevVm)
    }
    override public func touchLeaf(_ : TouchState,
                                   _ : Visitor) {}
    func updateSync(_ visit: Visitor) {}

    override func tapPlusButton() {
        print("🏛️ tapped LeafArchiveVm + button ")
        editing = true
    }
    override public func leafTitle() -> String { ArchiveVm.shared.nameNow }
}
