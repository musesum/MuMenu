//  Created by warren on 9/26/22.

import UIKit


public struct TouchMenuItem: Codable {
    
    public var time      : TimeInterval
    public var type      : String
    public var cornerStr : String
    public var menuKey   : Int
    public var treePath  : [Int] // last shown item on tree
    public var treeNow   : Int // hash of currently selected item
    public let thumb     : [Double]
    public let phase     : Int // UITouch.Phase
    
    public var nextXY: CGPoint {
        CGPoint(x: CGFloat(thumb[0]),
                y: CGFloat(thumb[1]))
    }
    
    public func isDone() -> Bool {
        return (phase == UITouch.Phase.ended.rawValue ||
                phase == UITouch.Phase.cancelled.rawValue)
    }
    
    // init with CGPoint
    public init(_ menuKey: Int,
                _ cornerStr: String,
                _ nodeType: MuNodeType,
                _ treePath: [Int],
                _ treeNow: Int,
                _ point: CGPoint,
                _ phase: UITouch.Phase) {
        
        self.menuKey = menuKey
        self.cornerStr = cornerStr
        self.type = nodeType.rawValue
        self.treePath = treePath
        self.treeNow = treeNow
        self.time = Date().timeIntervalSince1970
        self.thumb = [Double(point.x), Double(point.y)]
        self.phase = phase.rawValue
    }
    // init with thumb
    public init(_ menuKey: Int,
                _ cornerStr: String,
                _ nodeType: MuNodeType,
                _ treePath: [Int],
                _ treeNow: Int,
                _ thumb: [Double],
                _ phase: UITouch.Phase) {
        
        self.menuKey = menuKey
        self.cornerStr = cornerStr
        self.type = nodeType.rawValue
        self.treePath = treePath
        self.treeNow = treeNow
        self.time = Date().timeIntervalSince1970
        self.thumb = thumb
        self.phase = phase.rawValue
    }
    enum CodingKeys: String, CodingKey {
        case menuKey, cornerStr, type, time, treePath, treeNow, thumb, phase }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try menuKey   = container.decode(Int     .self , forKey: .menuKey   )
        try type      = container.decode(String  .self , forKey: .type      )
        try cornerStr = container.decode(String  .self , forKey: .cornerStr )
        try time      = container.decode(Double  .self , forKey: .time      )
        try treePath  = container.decode([Int]   .self , forKey: .treePath  )
        try treeNow   = container.decode(Int     .self , forKey: .treeNow   )
        try thumb     = container.decode([Double].self , forKey: .thumb     )
        try phase     = container.decode(Int     .self , forKey: .phase     )
    }
}
