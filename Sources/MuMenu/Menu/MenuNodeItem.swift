//  created by musesum on 9/26/22.

import SwiftUI

public struct MenuNodeItem: Codable {

    public var type     : String
    public var menuType : MenuType
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item

    public init(_ nodeVm : NodeVm) {

        self.type     = nodeVm.nodeType.rawValue
        self.menuType = nodeVm.branchVm.treeVm.menuType
        self.hashPath = nodeVm.menuTree.hashPath
        self.hashNow  = nodeVm.menuTree.hash
    }
    
    var treeVm: TreeVm? {
        return TreeVm.sideAxis[menuType.key]
    }
}

public struct MenuLeafItem: Codable {

    public var type      : String
    public var menuType  : MenuType
    public var hashPath  : [Int] // last shown item on tree
    public var hashNow   : Int // hash of currently selected item
    public let leafThumb : LeafThumb
    public let origin    : Bool

    public init(_ leafVm    : LeafVm,
                _ leafThumb : LeafThumb,
                _ origin    : Bool) {

        self.type      = leafVm.nodeType.rawValue
        self.menuType  = leafVm.branchVm.treeVm.menuType
        self.hashPath  = leafVm.menuTree.hashPath
        self.hashNow   = leafVm.menuTree.hash
        self.leafThumb = leafThumb
        self.origin    = origin
    }

    public var nextXY: CGPoint {
        return CGPoint(x: leafThumb.value.x, y: leafThumb.value.y)
    }

    var treeVm: TreeVm? {
        return TreeVm.sideAxis[menuType.key]
    }

}
