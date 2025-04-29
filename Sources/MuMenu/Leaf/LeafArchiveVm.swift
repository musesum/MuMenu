// created by musesum on 10/6/24

import SwiftUI
import MuPeer
import MuFlo

public class LeafArchiveVm: LeafVm {

    let archiveVm: ArchiveVm
    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          _ runTypes: [LeafRunwayType],
          _ archiveVm: ArchiveVm) {

        self.archiveVm = archiveVm
        super.init(menuTree, branchVm, prevVm, runTypes)
    }

    override public func touchLeaf(_: TouchState, _: Visitor) {}
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { archiveVm.nameNow }
    override public func syncVal(_ : Visitor) {}
}
