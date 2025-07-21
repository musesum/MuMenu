//  created by musesum on 1/8/23.

import SwiftUI
import MuFlo


public struct MenuItem: Codable, @unchecked Sendable {

    public enum MenuElement: String, CodingKey {
        case trees, node, leaf, touch }

    public let element  : MenuElement
    public let time     : TimeInterval
    public let menuType : MenuType
    public let phase    : Int // UITouch.Phase
    public let item     : Any?

    public init(trees: MenuTreesItem) {

        self.element  = .trees
        self.item     = trees
        self.time     = Date().timeIntervalSince1970
        self.menuType = trees.menuType
        self.phase    = trees.phase
    }

    public init(node: MenuNodeItem,
                _ phase : UITouch.Phase) {

        self.element  = .node
        self.item     = node
        self.time     = Date().timeIntervalSince1970
        self.menuType = node.menuType
        self.phase    = phase.rawValue
    }
    // via LeafVm::updateLeafPeers
    public init(leaf: MenuLeafItem,
                _ phase: UITouch.Phase) {

        self.element  = .leaf
        self.item     = leaf
        self.menuType = leaf.menuType
        self.phase    = phase.rawValue
        self.time     = Date().timeIntervalSince1970
    }

    public init(_ location: CGPoint, //touch.location(in: nil)
                _ phase: Int, // touch.phase.rawValue
                _ finger: Int, // touch.hash
                _ menuType: MenuType) {
        
        self.element  = .touch
        self.item     = MenuTouchItem(location, finger)
        self.phase    = phase
        self.menuType = menuType
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
        case .trees : try c.encode(item as? MenuTreesItem, forKey: .item)
        case .node  : try c.encode(item as? MenuNodeItem,  forKey: .item)
        case .leaf  : try c.encode(item as? MenuLeafItem,  forKey: .item)
        case .touch : try c.encode(item as? MenuTouchItem, forKey: .item)
        }
    }
    public init(from decoder: Decoder) throws {
        let c  = try decoder.container(keyedBy: CodingKeys.self)
        try time     = c.decode(Double  .self, forKey: .time  )
        try menuType = c.decode(MenuType.self, forKey: .menuType)
        try phase    = c.decode(Int     .self, forKey: .phase )
        element = MenuElement(rawValue: try c.decode(String.self, forKey: .element)) ?? .node
        switch element {
        case .trees : try item = c.decode(MenuTreesItem.self, forKey: .item)
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
        if let vm = (MenuTypeCornerVm[menuType.rawValue] ??
                     MenuTypeCornerVm[MenuType.flipNS(menuType.rawValue)]) {
            return vm
        } else {
            let menuIcon = menuType.icon
            let flip = MenuType.flipNS(menuType.rawValue)
            let flipIcon = MenuType(rawValue: flip).icon
            PrintLog("cannot find \(menuIcon) nor \(flipIcon)")
        }
        return nil
    }

}
