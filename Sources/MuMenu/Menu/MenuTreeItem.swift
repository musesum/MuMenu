// created by musesum on 6/27/25

import MuFlo

@MainActor
public struct MenuTreeItem: Codable {

    public let menuType : MenuType
    public let depth    : Int
    public let treeShow : TreeShow

    public init(_ treeVm: TreeVm) {
        self.menuType = treeVm.menuType
        self.depth = treeVm.depthShown
        self.treeShow = treeVm.treeShow
    }
    var treeVm: TreeVm? {
        return TreeVm.sideAxis[menuType.key]
    }

    func remoteTree() {
        if let treeVm {
            treeVm.remoteTree(depth: depth)
            treeVm.treeShow.setState(treeShow.state)
        }
    }
}
