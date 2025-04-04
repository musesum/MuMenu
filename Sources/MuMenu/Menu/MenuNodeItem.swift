//  created by musesum on 9/26/22.

import SwiftUI
@MainActor
public struct MenuNodeItem: Codable, Sendable {

    public let type     : String
    public let sideAxis : SideAxisId
    public let hashPath : [Int] // last shown item on tree
    public let hashNow  : Int // hash of currently selected item

    public init(_ nodeVm : NodeVm) {

        self.type     = nodeVm.nodeType.rawValue
        self.sideAxis = nodeVm.branchVm.treeVm.corner.sideAxis.rawValue
        self.hashPath = nodeVm.menuTree.hashPath
        self.hashNow  = nodeVm.menuTree.hash
    } 

    var treeVm: TreeVm? {
        return TreeVm.sideAxis[sideAxis]
    }
}
@MainActor
public struct MenuLeafItem: Codable, Sendable {

    public let type      : String
    public let sideAxis  : Int
    public let hashPath  : [Int] // last shown item on tree
    public let hashNow   : Int // hash of currently selected item
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
