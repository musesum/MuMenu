//  Created by warren on 9/26/22.

import SwiftUI
public typealias Thumb = [Double]

public struct MenuNodeItem: Codable {

    public var type     : String
    public var cornax   : Int
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item

    public init(_ nodeVm : MuNodeVm) {

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

    var treeVm: MuTreeVm? {
        return CornerAxisTreeVm[cornax]
    }
}

public struct MenuLeafItem: Codable {

    public var type     : String
    public var cornax   : Int
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item
    public let thumb    : Thumb

    public init(_ leafVm : MuLeafVm,
                _ thumb  : [Double]) {

        self.type      = leafVm.nodeType.rawValue
        self.cornax    = leafVm.branchVm.treeVm.cornerAxis.cornax.rawValue
        self.hashPath  = leafVm.node.hashPath
        self.hashNow   = leafVm.node.hash
        self.thumb     = thumb
    }

    enum CodingKeys: String, CodingKey {
        case type, cornax, hashPath, hashNow, thumb }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try type     = container.decode(String  .self, forKey: .type     )
        try cornax   = container.decode(Int     .self, forKey: .cornax   )
        try hashPath = container.decode([Int]   .self, forKey: .hashPath )
        try hashNow  = container.decode(Int     .self, forKey: .hashNow  )
        try thumb    = container.decode([Double].self, forKey: .thumb   )
    }
    public var nextXY: CGPoint {
        CGPoint(x: CGFloat(thumb[0]),
                y: CGFloat(thumb[1]))
    }

    var treeVm: MuTreeVm? {
        return CornerAxisTreeVm[cornax]
    }

}
