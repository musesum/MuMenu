//  created by musesum on 9/26/22.

import SwiftUI
@MainActor
public struct MenuNodeItem: Codable, Sendable {

    public let type     : String
    public let menuType : MenuType
    public let wordPath : [String] // last shown item on tree (string-based path)
    public let wordNow  : String   // name of currently selected item (string-based)

    public init(_ nodeVm : NodeVm) {

        self.type     = nodeVm.nodeType.rawValue
        self.menuType = nodeVm.branchVm.treeVm.menuType
        self.wordPath = nodeVm.menuTree.wordPath
        self.wordNow  = nodeVm.menuTree.flo.name
    }
    
    var treeVm: TreeVm? {
        #if os(visionOS)
        let flipKey = MenuType(rawValue: MenuType.flipNS(menuType.rawValue)).key
        return TreeVm.sideAxis[menuType.key] ?? TreeVm.sideAxis[flipKey]
        #else
        return TreeVm.sideAxis[menuType.key]
        #endif
    }
}
@MainActor
public struct MenuLeafItem: Codable, Sendable {

    public let type      : String
    public let menuType  : MenuType
    public let wordPath  : [String] // last shown item on tree (string-based path)
    public let wordNow   : String   // name of currently selected item (string-based)
    public let leafThumb : LeafThumb
    public let origin    : Bool

    public init(_ leafVm    : LeafVm,
                _ leafThumb : LeafThumb,
                _ origin    : Bool) {

        self.type      = leafVm.nodeType.rawValue
        self.menuType  = leafVm.branchVm.treeVm.menuType
        self.wordPath  = leafVm.menuTree.wordPath
        self.wordNow   = leafVm.menuTree.flo.name
        self.leafThumb = leafThumb
        self.origin    = origin
    }

    public var nextXY: CGPoint {
        return CGPoint(x: leafThumb.value.x, y: leafThumb.value.y)
    }
    // redun
    var treeVm: TreeVm? {
        #if os(visionOS)
        let flipKey = MenuType(rawValue: MenuType.flipNS(menuType.rawValue)).key
        return TreeVm.sideAxis[menuType.key] ?? TreeVm.sideAxis[flipKey]
        #else
        return TreeVm.sideAxis[menuType.key]
        #endif
    }

}
