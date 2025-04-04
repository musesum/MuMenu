// created by musesum on 4/1/25

import SwiftUI
import MuFlo

public typealias SideAxisId = Int

public struct MenuTreeItem: Codable, Sendable {
    
    public var sideAxis : SideAxisId = 0
    public var depth    : Int = 0
    public var start    : Int = 0

    public init(sideAxis : Int,
                depth    : Int,
                start    : Int) {

        self.sideAxis = sideAxis
        self.depth    = depth
        self.start    = start
    }

    var treeVm: TreeVm? {
        return TreeVm.sideAxis[sideAxis]
    }

    func showTree(_ fromRemote: Bool) {
        Task { @MainActor in
            treeVm?.showTree(start: start,
                             depth: depth,
                             "item",fromRemote)
        }
    }
}
