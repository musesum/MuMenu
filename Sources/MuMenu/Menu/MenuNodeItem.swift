//  created by musesum on 9/26/22.

import SwiftUI

public struct MenuNodeItem: Codable {

    public var type     : String
    public var cornax   : CornerAxisId
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item

    public init(_ nodeVm : NodeVm) {

        self.type     = nodeVm.nodeType.rawValue
        self.cornax   = nodeVm.branchVm.treeVm.cornerAxis.cornax.rawValue
        self.hashPath = nodeVm.node.hashPath
        self.hashNow  = nodeVm.node.hash
    } 

    enum CodingKeys: String, CodingKey {
        case type, cornax, hashPath, hashNow }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try type     = container.decode(String.self, forKey: .type    )
        try cornax   = container.decode(Int   .self, forKey: .cornax  )
        try hashPath = container.decode([Int] .self, forKey: .hashPath)
        try hashNow  = container.decode(Int   .self, forKey: .hashNow )
    }

    var treeVm: TreeVm? {
        return CornerAxisTreeVm[cornax]
    }
}

public struct MenuLeafItem: Codable {

    public var type     : String
    public var cornax   : Int
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item
    public let thumbs   : ValTween

    public init(_ leafVm : LeafVm,
                _ thumbs : ValTween) {

        self.type      = leafVm.nodeType.rawValue
        self.cornax    = leafVm.branchVm.treeVm.cornerAxis.cornax.rawValue
        self.hashPath  = leafVm.node.hashPath
        self.hashNow   = leafVm.node.hash
        self.thumbs    = thumbs
    }

    enum CodingKeys: String, CodingKey { case type, cornax, hashPath, hashNow, thumbs }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try type     = container.decode(String   .self, forKey: .type    )
        try cornax   = container.decode(Int      .self, forKey: .cornax  )
        try hashPath = container.decode([Int]    .self, forKey: .hashPath)
        try hashNow  = container.decode(Int      .self, forKey: .hashNow )
        try thumbs   = container.decode(ValTween .self, forKey: .thumbs  )
    }
    public var nextXY: CGPoint {
        return CGPoint(x: thumbs.val.x, y: thumbs.val.y)
    }

    var treeVm: TreeVm? {
        
//        for key in CornerAxisTreeVm.keys {
//            print(key, terminator: " ")
//        }

        if let vm = CornerAxisTreeVm[cornax] { return vm }

        #if os(visionOS)

        for vm in CornerAxisTreeVm.values {
            return vm
        }
        #endif
        return nil
    }

}
