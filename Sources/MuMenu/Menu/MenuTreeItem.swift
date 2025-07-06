// created by musesum on 6/27/25

import Foundation

public struct MenuTreeItem: Codable {

    public let menuType : MenuType
    public let depth    : Int
    public let start    : Int

    public init(_ treeVm: TreeVm) {
        self.menuType = treeVm.menuType
        self.depth = treeVm.depthShown
        self.start = treeVm.startIndex
    }
    var treeVm: TreeVm? {
        return TreeVm.sideAxis[menuType.key]
    }

    func showTree(_ fromRemote: Bool) {
        treeVm?.showTree(start: start,
                         depth: depth,
                         "item",fromRemote)
    }
}
