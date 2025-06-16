// created by musesum on 6/15/25

import Foundation

public struct MenuRootItem: Codable {

    public var trees    : [MenuTreeItem]
    public var menuType : Int // MenuType.rawValue
    public var phase    : Int // UITouch.Phase

    public init(_ rootVm: RootVm) {
        var trees = [MenuTreeItem]()
        for treeVm in rootVm.treeVms {
            trees.append(MenuTreeItem(treeVm))
        }
        self.trees = trees
        self.menuType = rootVm.cornerType.rawValue
        self.phase = rootVm.touchState.phase.rawValue
    }

    enum CodingKeys: String, CodingKey { case trees, menuType, phase }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try trees    = c.decode([MenuTreeItem].self, forKey: .trees )
        try menuType = c.decode(Int.self, forKey: .menuType)
        try phase    = c.decode(Int.self, forKey: .phase )
    }
}
