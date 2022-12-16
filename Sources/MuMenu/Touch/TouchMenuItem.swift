//  Created by warren on 9/26/22.

import UIKit

public struct TouchMenuItem: Codable {
    
    public var time      : TimeInterval
    public var cornerStr : String
    public var menuKey   : Int
    public var hashPath  : [Int]
    public let nextX     : Float
    public let nextY     : Float
    public let phase     : Int // UITouch.Phase

    public var nextXY: CGPoint {
        CGPoint(x: CGFloat(nextX),
                y: CGFloat(nextY))
    }

    public func isDone() -> Bool {
        return (phase == UITouch.Phase.ended.rawValue ||
                phase == UITouch.Phase.cancelled.rawValue)
    }

    public init(_ menuKey: Int,
                _ cornerStr: String,
                _ hashPath: [Int],
                _ nextXY: CGPoint,
                _ phase: UITouch.Phase) {
        
        self.menuKey = menuKey
        self.cornerStr = cornerStr
        self.hashPath = hashPath
        self.time = Date().timeIntervalSince1970
        self.nextX = Float(nextXY.x)
        self.nextY = Float(nextXY.y)
        self.phase = phase.rawValue
    }
    
    enum CodingKeys: String, CodingKey {
        case menuKey, cornerStr, time, hashPath, nextX, nextY, phase }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try menuKey   = container.decode(Int    .self , forKey: .menuKey   )
        try cornerStr = container.decode(String .self , forKey: .cornerStr )
        try time      = container.decode(Double .self , forKey: .time      )
        try hashPath  = container.decode([Int]  .self , forKey: .hashPath  )
        try nextX     = container.decode(Float  .self , forKey: .nextX     )
        try nextY     = container.decode(Float  .self , forKey: .nextY     )
        try phase     = container.decode(Int    .self , forKey: .phase     )
    }
}
