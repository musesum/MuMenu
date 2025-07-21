// created by musesum on 6/15/25

import MuFlo
@MainActor
public struct MenuTreesItem: Codable {

    public var treeItems : [MenuTreeItem]
    public var menuType  : MenuType
    public var phase     : Int // UITouch.Phase

    public init(_ rootVm: RootVm) {
        var treeItems = [MenuTreeItem]()
        for treeVm in rootVm.treeVms {
            treeItems.append(MenuTreeItem(treeVm))
        }
        self.treeItems = treeItems
        self.menuType = rootVm.cornerType
        self.phase = rootVm.touchState.phase.rawValue
    }
}

