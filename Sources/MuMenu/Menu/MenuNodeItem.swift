//  created by musesum on 9/26/22.

import SwiftUI

public struct MenuNodeItem: Codable {

    public var type     : String
    public var sideAxis : SideAxisId
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item

    public init(_ nodeVm : NodeVm) {

        self.type     = nodeVm.nodeType.rawValue
        self.sideAxis = nodeVm.branchVm.treeVm.corner.sideAxis.rawValue
        self.hashPath = nodeVm.menuTree.hashPath
        self.hashNow  = nodeVm.menuTree.hash
    } 

    enum CodingKeys: String, CodingKey {
        case type, sideAxis, hashPath, hashNow }
    
    nonisolated public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try type     = c.decode(String.self, forKey: .type    )
        try sideAxis = c.decode(Int   .self, forKey: .sideAxis)
        try hashPath = c.decode([Int] .self, forKey: .hashPath)
        try hashNow  = c.decode(Int   .self, forKey: .hashNow )
    }

    var treeVm: TreeVm? {
        return TreeVm.sideAxis[sideAxis]
    }
}

public struct MenuLeafItem: Codable {

    public var type      : String
    public var sideAxis  : Int
    public var hashPath  : [Int] // last shown item on tree
    public var hashNow   : Int // hash of currently selected item
    public let leafThumb : LeafThumb

    public init(_ leafVm    : LeafVm,
                _ leafThumb : LeafThumb) {

        self.type     = leafVm.nodeType.rawValue
        self.sideAxis = leafVm.branchVm.treeVm.corner.sideAxis.rawValue
        self.hashPath = leafVm.menuTree.hashPath
        self.hashNow  = leafVm.menuTree.hash
        self.leafThumb = leafThumb
    }

    enum CodingKeys: String, CodingKey { case type, sideAxis, hashPath, hashNow, leafThumb }

    nonisolated public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try type      = c.decode(String   .self, forKey: .type    )
        try sideAxis  = c.decode(Int      .self, forKey: .sideAxis)
        try hashPath  = c.decode([Int]    .self, forKey: .hashPath)
        try hashNow   = c.decode(Int      .self, forKey: .hashNow )
        try leafThumb = c.decode(LeafThumb.self, forKey: .leafThumb)
    }
    public var nextXY: CGPoint {
        return CGPoint(x: leafThumb.value.x, y: leafThumb.value.y)
    }

    var treeVm: TreeVm? {
        return TreeVm.sideAxis[sideAxis]
    }

}
