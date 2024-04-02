//  created by musesum on 9/26/22.

import SwiftUI

public struct MenuNodeItem: Codable {

    public var type     : String
    public var sideAxis : SideAxisId
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item

    public init(_ nodeVm : NodeVm) {

        self.type     = nodeVm.nodeType.rawValue
        self.sideAxis = nodeVm.branchVm.treeVm.cornerItem.sideAxis.rawValue
        self.hashPath = nodeVm.node.hashPath
        self.hashNow  = nodeVm.node.hash
    } 

    enum CodingKeys: String, CodingKey {
        case type, sideAxis, hashPath, hashNow }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try type     = container.decode(String.self, forKey: .type    )
        try sideAxis = container.decode(Int   .self, forKey: .sideAxis)
        try hashPath = container.decode([Int] .self, forKey: .hashPath)
        try hashNow  = container.decode(Int   .self, forKey: .hashNow )
    }

    var treeVm: TreeVm? {
        return TreeVm.sideAxis[sideAxis]
    }
}

public struct MenuLeafItem: Codable {

    public var type     : String
    public var sideAxis   : Int
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item
    public let thumbs   : ValTween

    public init(_ leafVm : LeafVm,
                _ thumbs : ValTween) {

        self.type      = leafVm.nodeType.rawValue
        self.sideAxis  = leafVm.branchVm.treeVm.cornerItem.sideAxis.rawValue
        self.hashPath  = leafVm.node.hashPath
        self.hashNow   = leafVm.node.hash
        self.thumbs    = thumbs
    }

    enum CodingKeys: String, CodingKey { case type, sideAxis, hashPath, hashNow, thumbs }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try type     = container.decode(String   .self, forKey: .type    )
        try sideAxis = container.decode(Int      .self, forKey: .sideAxis  )
        try hashPath = container.decode([Int]    .self, forKey: .hashPath)
        try hashNow  = container.decode(Int      .self, forKey: .hashNow )
        try thumbs   = container.decode(ValTween .self, forKey: .thumbs  )
    }
    public var nextXY: CGPoint {
        return CGPoint(x: thumbs.val.x, y: thumbs.val.y)
    }

    var treeVm: TreeVm? {
        return TreeVm.sideAxis[sideAxis]
    }

}
