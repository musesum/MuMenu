//  Created by warren on 9/26/22.

import SwiftUI

public struct MenuRemoteItem: Codable {
    
    public var time       : TimeInterval
    public var type       : String
    public var corner     : Int
    public var axis       : Int8
    public var menuKey    : Int
    public var hashPath   : [Int] // last shown item on tree
    public var hashNow    : Int // hash of currently selected item
    public var startIndex : Int
    public let thumb      : [Double]
    public let phase      : Int // UITouch.Phase
    
    public var nextXY: CGPoint {
        CGPoint(x: CGFloat(thumb[0]),
                y: CGFloat(thumb[1]))
    }
    
    public func isDone() -> Bool {
        return (phase == UITouch.Phase.ended.rawValue ||
                phase == UITouch.Phase.cancelled.rawValue)
    }

    public init(menuKey    : Int,
                corner     : MuCorner,
                axis       : Axis,
                nodeType   : MuMenuType,
                hashPath   : [Int],
                hashNow    : Int,
                startIndex : Int,
                thumb      : [Double],
                phase      : UITouch.Phase) {
        
        self.menuKey = menuKey
        self.corner = corner.rawValue
        self.axis = axis.rawValue
        self.type = nodeType.rawValue
        self.hashPath = hashPath
        self.hashNow = hashNow
        self.startIndex = startIndex
        self.time = Date().timeIntervalSince1970
        self.thumb = thumb
        self.phase = phase.rawValue
    }

    public init(nodeVm     : MuNodeVm,
                startIndex : Int,
                thumb      : [Double],
                phase      : UITouch.Phase) {

        self.menuKey  = (nodeVm.nodeType.isLeaf ? "leaf" : "node").hash
        self.corner   = nodeVm.branchVm.treeVm.cornerAxis.corner.rawValue
        self.axis     = nodeVm.branchVm.treeVm.cornerAxis.axis.rawValue
        self.type     = nodeVm.nodeType.rawValue
        self.hashPath = nodeVm.node.hashPath
        self.hashNow  = nodeVm.node.hash

        self.startIndex = startIndex
        self.time = Date().timeIntervalSince1970
        self.thumb = thumb
        self.phase = phase.rawValue
    }

    // local for translating position XY
    public init(nodeVm     : MuNodeVm,
                touch      : UITouch) {

        self.menuKey  = touch.hash
        self.corner   = nodeVm.branchVm.treeVm.cornerAxis.corner.rawValue
        self.axis     = nodeVm.branchVm.treeVm.cornerAxis.axis.rawValue
        self.type     = nodeVm.nodeType.rawValue

        self.hashPath = [] // ignored
        self.hashNow  = 0   // ignored
        self.startIndex = 0 // ignored
        self.time = Date().timeIntervalSince1970


        self.thumb = (touch.phase.isDone()
                      ? [0,0]
                      : touch.location(in: nil).doubles())
        self.phase = touch.phase.rawValue
    }






    enum CodingKeys: String, CodingKey {
        case menuKey, corner, axis, type, time, hashPath, hashNow, startIndex, thumb, phase }
    
    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try menuKey    = container.decode(Int     .self, forKey: .menuKey   )
        try type       = container.decode(String  .self, forKey: .type      )
        try corner     = container.decode(Int     .self, forKey: .corner    )
        try axis       = container.decode(Int8    .self, forKey: .axis      )
        try time       = container.decode(Double  .self, forKey: .time      )
        try hashPath   = container.decode([Int]   .self, forKey: .hashPath  )
        try hashNow    = container.decode(Int     .self, forKey: .hashNow   )
        try startIndex = container.decode(Int     .self, forKey: .startIndex)
        try thumb      = container.decode([Double].self, forKey: .thumb     )
        try phase      = container.decode(Int     .self, forKey: .phase     )
    }
}
