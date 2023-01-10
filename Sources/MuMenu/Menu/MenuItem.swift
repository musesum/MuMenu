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
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try corner     = container.decode(Int .self, forKey: .corner)
        try axis       = container.decode(Int8.self, forKey: .axis  )
        try depth      = container.decode(Int .self, forKey: .depth )
        try start      = container.decode(Int .self, forKey: .start )
    }
    var treeVm: MuTreeVm? {
        let key = CornerAxis.Key(corner, axis)
        return CornerAxisTreeVm[key]
    }
    func showTree(_ fromRemote: Bool) {
        // log("remote showTree", [start, depth])
        treeVm?.showTree(start: start,
                         depth: depth,
                         "item",fromRemote)
    }

}

public struct MenuRootItem: Codable {

    public var trees: [MenuTreeItem]

    public init(_ root: MuRootVm) {
        var trees = [MenuTreeItem]()
        for treeVm in root.treeVms {
            trees.append(MenuTreeItem(treeVm))
        }
        self.trees = trees
    }

    enum CodingKeys: String, CodingKey { case trees }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try trees = container.decode([MenuTreeItem].self, forKey: .trees)
    }
}

public struct MenuItem: Codable {

    public var key: Int
    public var time: TimeInterval
    public var corner: Int
    public var root: MenuRootItem?
    public var node: MenuNodeItem?
    public var touch: MenuTouchItem?
    public let phase: Int // UITouch.Phase

    public init(_ root: MuRootVm) {
        self.key = "root".hash
        self.time = Date().timeIntervalSince1970
        self.corner = root.corner.rawValue
        self.root = MenuRootItem(root)
        self.phase = (root.touchState?.phase ?? .began).rawValue
        // log("MenuRootItem", [self.phase])
    }

    public init(_ nodeVm : MuNodeVm,
                _ thumb : [Double],
                _ phase : UITouch.Phase) {

        self.key   = (nodeVm.nodeType.isLeaf ? "leaf" : "node").hash
        self.time  = Date().timeIntervalSince1970
        self.corner = nodeVm.rootVm.corner.rawValue
        self.node  = MenuNodeItem(nodeVm,thumb)
        self.phase = phase.rawValue
        // log("MenuNodeItem", [self.phase])
    }

    public init(_ touch: UITouch,
                _ corner: MuCorner) {
        
        self.key   = touch.hash
        self.time  = Date().timeIntervalSince1970
        self.touch = MenuTouchItem(touch)
        self.corner = corner.rawValue
        self.phase = touch.phase.rawValue
        // log("MenuTouchItem", [self.phase])
    }

    enum CodingKeys: String, CodingKey {
        case key, time, corner, root, node, touch, phase }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try key   = container.decode(Int.self, forKey: .key)
        try time  = container.decode(Double.self, forKey: .time)
        try corner = container.decode(Int.self, forKey: .corner)
        try root  = container.decodeIfPresent(MenuRootItem.self, forKey: .root)
        try node  = container.decodeIfPresent(MenuNodeItem.self, forKey: .node)
        try touch = container.decodeIfPresent(MenuTouchItem.self, forKey:.touch)
        try phase = container.decode(Int.self, forKey: .phase    )
    }
    var isDone: Bool {
        (phase == UITouch.Phase.ended.rawValue ||
         phase == UITouch.Phase.cancelled.rawValue)
    }
    var touchVm: MuTouchVm? {
        CornerTouchVm[corner]
    }

}
