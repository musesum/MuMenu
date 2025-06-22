//  created by musesum on 1/8/23.

import SwiftUI
import MuFlo

public struct MenuTreeItem: Codable {

    public var menuType : MenuType
    public var depth    : Int
    public var start    : Int

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

public enum MenuElement: String, CodingKey {
    case root, node, leaf, touch }

public struct MenuItem: Codable {

    public var element  : MenuElement
    public var time     : TimeInterval
    public var menuType : Int // MenuType.rawValue
    public let phase    : Int // UITouch.Phase
    public let item     : Any?

    public init(root: MenuRootItem) {

        self.element  = .root
        self.item     = root
        self.time     = Date().timeIntervalSince1970
        self.menuType = root.menuType
        self.phase    = root.phase
    }

    public init(node: MenuNodeItem,
                _ phase : UITouch.Phase) {

        self.element  = .node
        self.item     = node
        self.time     = Date().timeIntervalSince1970
        self.menuType = node.menuType.rawValue
        self.phase    = phase.rawValue
    }
    // via LeafVm::updateLeafPeers
    public init(leaf: MenuLeafItem,
                _ phase: UITouch.Phase) {

        self.element  = .leaf
        self.item     = leaf
        self.menuType = leaf.menuType.rawValue
        self.phase    = phase.rawValue
        self.time     = Date().timeIntervalSince1970
    }

    public init(_ touch: UITouch,
                _ menuType: MenuType) {
        
        self.element  = .touch
        self.item     = MenuTouchItem(touch)
        self.menuType = menuType.rawValue
        self.phase    = touch.phase.rawValue
        self.time     = Date().timeIntervalSince1970
    }

    enum CodingKeys: String, CodingKey {
        case element, time, menuType, phase, item }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(time,     forKey: .time  )
        try c.encode(menuType, forKey: .menuType)
        try c.encode(phase,    forKey: .phase )
        try c.encode(element.stringValue, forKey: .element)
        switch element {
        case .root  : try c.encode(item as? MenuRootItem,  forKey: .item)
        case .node  : try c.encode(item as? MenuNodeItem,  forKey: .item)
        case .leaf  : try c.encode(item as? MenuLeafItem,  forKey: .item)
        case .touch : try c.encode(item as? MenuTouchItem, forKey: .item)
        }
    }
    public init(from decoder: Decoder) throws {
        let c  = try decoder.container(keyedBy: CodingKeys.self)
        try time     = c.decode(Double.self, forKey: .time  )
        try menuType = c.decode(Int   .self, forKey: .menuType)
        try phase    = c.decode(Int   .self, forKey: .phase )
        element = MenuElement(rawValue: try c.decode(String.self, forKey: .element)) ?? .node
        switch element {
        case .root  : try item = c.decode(MenuRootItem .self, forKey: .item)
        case .node  : try item = c.decode(MenuNodeItem .self, forKey: .item)
        case .leaf  : try item = c.decode(MenuLeafItem .self, forKey: .item)
        case .touch : try item = c.decode(MenuTouchItem.self, forKey: .item)
        }
    }

    var key: Int {
        switch element {
            case .touch: return (item as? MenuTouchItem)?.finger ?? element.rawValue.hash
            default: return element.rawValue.hash
        }
    }
    var isDone: Bool {
        (phase == UITouch.Phase.ended.rawValue ||
         phase == UITouch.Phase.cancelled.rawValue)
    }
    var cornerVm: CornerVm? {
        if let vm = (MenuTypeCornerVm[menuType] ??
                     MenuTypeCornerVm[MenuType.flipNS(menuType)]) {
            return vm
        } else {
            let menuIcon = MenuType(rawValue: menuType).icon
            let flip = MenuType.flipNS(menuType)
            let flipIcon = MenuType(rawValue: flip).icon
            PrintLog("cannot find \(menuIcon) nor \(flipIcon)")
        }
        return nil
    }

}
