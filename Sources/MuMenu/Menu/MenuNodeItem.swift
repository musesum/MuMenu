//  Created by warren on 9/26/22.

import SwiftUI

public struct MenuNodeItem: Codable {

    public var type     : String
    public var corner   : Int
    public var axis     : Int8
    public var hashPath : [Int] // last shown item on tree
    public var hashNow  : Int // hash of currently selected item
    public let thumb    : [Double]

    public var nextXY: CGPoint {
        CGPoint(x: CGFloat(thumb[0]),
                y: CGFloat(thumb[1]))
    }

    public init(_ nodeVm : MuNodeVm,
                _ thumb  : [Double]) {

        let cornerAxis = nodeVm.branchVm.treeVm.cornerAxis
        self.type     = nodeVm.nodeType.rawValue
        self.corner   = cornerAxis.corner.rawValue
        self.axis     = cornerAxis.axis.rawValue
        self.hashPath = nodeVm.node.hashPath
        self.hashNow  = nodeVm.node.hash
        self.thumb    = thumb
    }

    // local for translating position XY
    public init(nodeVm : MuNodeVm,
                touch  : UITouch) {
        let cornerAxis = nodeVm.branchVm.treeVm.cornerAxis
        self.type   = nodeVm.nodeType.rawValue
        self.corner = cornerAxis.corner.rawValue
        self.axis   = cornerAxis.axis.rawValue
        self.hashPath = [] // ignored
        self.hashNow  = 0   // ignored

        self.thumb = (touch.phase.isDone()
                      ? [0,0]
                      : touch.location(in: nil).doubles())
    }

    enum CodingKeys: String, CodingKey {
        case type, corner, axis, hashPath, hashNow,  thumb }
    
    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try type     = container.decode(String  .self, forKey: .type     )
        try corner   = container.decode(Int     .self, forKey: .corner   )
        try axis     = container.decode(Int8    .self, forKey: .axis     )
        try hashPath = container.decode([Int]   .self, forKey: .hashPath )
        try hashNow  = container.decode(Int     .self, forKey: .hashNow  )
        try thumb    = container.decode([Double].self, forKey: .thumb    )
    }

    var treeVm: MuTreeVm? {
        let key = CornerAxis.Key(corner, axis)
        return CornerAxisTreeVm[key]
    }
    
}
