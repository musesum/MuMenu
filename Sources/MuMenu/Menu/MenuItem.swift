//  Created by warren on 1/8/23.

import SwiftUI

public struct MenuTreeItem: Codable {
    
    public var corner : Int
    public var axis   : Int8
    public var depth  : Int
    public var start  : Int

    public init(_ treeVm: MuTreeVm) {
        self.corner = treeVm.cornerAxis.corner.rawValue
        self.axis   = treeVm.cornerAxis.axis.rawValue
        self.depth  = treeVm.depthShown
        self.start  = treeVm.startIndex
    }

    enum CodingKeys: String, CodingKey {
        case corner, axis, depth, start
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try corner = c.decode(Int .self, forKey: .corner)
        try axis   = c.decode(Int8.self, forKey: .axis  )
        try depth  = c.decode(Int .self, forKey: .depth )
        try start  = c.decode(Int .self, forKey: .start )
    }
    var treeVm: MuTreeVm? {
        let key = CornerAxis.Key(corner, axis)
        return CornerAxisTreeVm[key]
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

    public init(_ root: MuRootVm) {
        var trees = [MenuTreeItem]()
        for treeVm in root.treeVms {
            trees.append(MenuTreeItem(treeVm))
        }
        self.trees = trees
        self.corner = root.corner.rawValue
        self.phase = (root.touchState?.phase ?? .began).rawValue
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
                _ phase : UITouch.Phase) {

        self.type   = .node
        self.item   = node

        self.time   = Date().timeIntervalSince1970
        self.corner = node.corner
        self.phase  = phase.rawValue

        // log("MenuNodeItem", [self.phase])
    }

    public init(leaf: MenuLeafItem,
                _ phase : UITouch.Phase) {

        self.type   = .leaf
        self.item   = leaf

        self.time   = Date().timeIntervalSince1970
        self.corner = leaf.corner
        self.phase  = phase.rawValue

        // log("MenuNodeItem", [self.phase])
    }

    public init(_ touch: UITouch,
                _ corner: MuCorner) {
        
        self.type   = .touch
        self.item   = MenuTouchItem(touch)

        self.time   = Date().timeIntervalSince1970
        self.corner = corner.rawValue //??? ambiguous
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
            case .root:  try item  = c.decode(MenuRootItem .self, forKey: .item)
            case .node:  try item  = c.decode(MenuNodeItem .self, forKey: .item)
            case .leaf:  try item  = c.decode(MenuLeafItem .self, forKey: .item)
            case .touch: try item  = c.decode(MenuTouchItem.self, forKey: .item)
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
