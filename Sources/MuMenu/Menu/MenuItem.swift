//  created by musesum on 1/8/23.

import SwiftUI
import MuFlo

public typealias CornerAxisId = Int

public struct MenuTreeItem: Codable {

    public var cornax : CornerAxisId //Int
    public var depth  : Int
    public var start  : Int

    public init(_ treeVm: MuTreeVm) {
        self.cornax = treeVm.cornerAxis.cornax.rawValue
        self.depth  = treeVm.depthShown
        self.start  = treeVm.startIndex
    }

    enum CodingKeys: String, CodingKey {
        case cornax, depth, start
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try cornax = c.decode(Int.self, forKey: .cornax) // CornerAxisId
        try depth  = c.decode(Int.self, forKey: .depth )
        try start  = c.decode(Int.self, forKey: .start )
    }
    var treeVm: MuTreeVm? {
        return CornerAxisTreeVm[cornax]
    }
    func showTree(_ fromRemote: Bool) {
        treeVm?.showTree(start: start,
                         depth: depth,
                         "item",fromRemote)
    }

}

public struct MenuRootItem: Codable {

    public var trees  : [MenuTreeItem]
    public var corner : Int
    public var phase  : Int // UITouch.Phase

    public init(_ rootVm: MuRootVm) {
        var trees = [MenuTreeItem]()
        for treeVm in rootVm.treeVms {
            trees.append(MenuTreeItem(treeVm))
        }
        self.trees = trees
        self.corner = rootVm.corner.rawValue
        self.phase = rootVm.touchState.phase.rawValue
    }

    enum CodingKeys: String, CodingKey { case trees, corner, phase }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try trees  = c.decode([MenuTreeItem].self, forKey: .trees )
        try corner = c.decode(Int           .self, forKey: .corner)
        try phase  = c.decode(Int           .self, forKey: .phase )
    }
}

public enum MenuType: String, CodingKey {
    case root, node, leaf, touch }

public struct MenuItem: Codable {

    public var type   : MenuType
    public var time   : TimeInterval
    public var corner : Int
    public let phase  : Int // UITouch.Phase
    public let item   : Any?

    public init(root: MenuRootItem) {

        self.type   = .root
        self.item   = root

        self.time   = Date().timeIntervalSince1970
        self.corner = root.corner
        self.phase  = root.phase

        // log("MenuRootItem", [self.phase])
    }

    public init(node: MenuNodeItem,
                _ corner: CornerOps,
                _ phase : UITouch.Phase) {

        self.type   = .node
        self.item   = node

        self.time   = Date().timeIntervalSince1970
        self.corner = corner.rawValue
        self.phase  = phase.rawValue

        // log("MenuNodeItem", [self.phase])
    }

    public init(leaf: MenuLeafItem,
                _ corner: CornerOps,
                _ phase : UITouch.Phase) {

        self.type   = .leaf
        self.item   = leaf

        self.time   = Date().timeIntervalSince1970
        self.corner = corner.rawValue
        self.phase  = phase.rawValue

        // log("MenuNodeItem", [self.phase])
    }

    public init(_ touch: UITouch,
                _ corner: CornerOps) {
        
        self.type   = .touch
        self.item   = MenuTouchItem(touch)

        self.time   = Date().timeIntervalSince1970
        self.corner = corner.rawValue
        self.phase  = touch.phase.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case type, time, corner, phase, item }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type.stringValue, forKey: .type)
        try c.encode(time   , forKey: .time  )
        try c.encode(corner , forKey: .corner)
        try c.encode(phase  , forKey: .phase )
        switch type {
            case .root : try c.encode(item as? MenuRootItem , forKey: .item)
            case .node : try c.encode(item as? MenuNodeItem , forKey: .item)
            case .leaf : try c.encode(item as? MenuLeafItem , forKey: .item)
            case .touch: try c.encode(item as? MenuTouchItem, forKey: .item)
        }
    }
    public init(from decoder: Decoder) throws {
        let c  = try decoder.container(keyedBy: CodingKeys.self)
        type = MenuType(rawValue: try c.decode(String.self, forKey: .type)) ?? .node
        try time   = c.decode(Double.self, forKey: .time  )
        try corner = c.decode(Int   .self, forKey: .corner)
        try phase  = c.decode(Int   .self, forKey: .phase )
        switch type {
            case .root : try item = c.decode(MenuRootItem .self, forKey: .item)
            case .node : try item = c.decode(MenuNodeItem .self, forKey: .item)
            case .leaf : try item = c.decode(MenuLeafItem .self, forKey: .item)
            case .touch: try item = c.decode(MenuTouchItem.self, forKey: .item)
        } 
    }

    var key: Int {
        switch type {
            case .touch: return (item as? MenuTouchItem)?.finger ?? type.rawValue.hash
            default: return type.rawValue.hash
        }
    }
    var isDone: Bool {
        (phase == UITouch.Phase.ended.rawValue ||
         phase == UITouch.Phase.cancelled.rawValue)
    }
    var touchVm: MuTouchVm? {
        CornerTouchVm[corner]
    }

}
