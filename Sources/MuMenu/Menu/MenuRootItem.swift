// created by musesum on 4/1/25

import SwiftUI
import MuFlo

@MainActor
public struct MenuRootItem: Codable, Sendable {

    public let trees    : [MenuTreeItem]
    public let cornerOp : Int
    public let phase    : Int // UITouch.Phase

    public init(_ rootVm: RootVm) {
        var trees = [MenuTreeItem]()
        for treeVm in rootVm.treeVms {
            let item = MenuTreeItem (
                sideAxis : treeVm.corner.sideAxis.rawValue,
                depth : treeVm.depthShown,
                start : treeVm.startIndex)

            trees.append(item)
        }
        self.trees = trees
        self.cornerOp = rootVm.cornerOp.rawValue
        self.phase = rootVm.touchState.phase.rawValue
    }
}
