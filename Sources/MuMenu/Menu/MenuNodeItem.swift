//  Created by warren on 9/26/22.

import SwiftUI
public typealias Thumb = [Double]
public typealias Thumbs = [[Double]]

public struct MenuNodeItem: Codable {

    public var type     : String
    public var cornax   : CornerAxisId
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
    public let thumbs   : Thumbs

    public init(_ leafVm : MuLeafVm,
                _ thumbs : Thumbs) {

        self.type      = leafVm.nodeType.rawValue
        self.cornax    = leafVm.branchVm.treeVm.cornerAxis.cornax.rawValue
        self.hashPath  = leafVm.node.hashPath
        self.hashNow   = leafVm.node.hash
        self.thumbs    = thumbs
    }

    enum CodingKeys: String, CodingKey {
        case type, cornax, hashPath, hashNow, thumbs }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try type     = container.decode(String.self, forKey: .type     )
        try cornax   = container.decode(Int   .self, forKey: .cornax   )
        try hashPath = container.decode([Int] .self, forKey: .hashPath )
        try hashNow  = container.decode(Int   .self, forKey: .hashNow  )
        try thumbs   = container.decode(Thumbs.self, forKey: .thumbs   )
    }
    public var nextXY: CGPoint {
        do {

            let x = try thumbs[0][0]
            let y = try thumbs[0][1]
            let point = CGPoint(x: CGFloat(x),
                                y: CGFloat(y))
            return point
        } catch {
            return .zero
        }

    }

    var treeVm: MuTreeVm? {
        return CornerAxisTreeVm[cornax]
    }

}
