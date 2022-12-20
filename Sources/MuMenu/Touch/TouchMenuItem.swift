//  Created by warren on 9/26/22.

import UIKit


public struct TouchMenuItem: Codable {
    
    public var time      : TimeInterval
    public var type      : String
    public var cornerStr : String
    public var menuKey   : Int
    public var hashPath  : [Int]
    public let point     : [Float]
    public let phase     : Int // UITouch.Phase
    
    public var nextXY: CGPoint {
        CGPoint(x: CGFloat(point[0]),
                y: CGFloat(point[1]))
    }
    
    public func isDone() -> Bool {
        return (phase == UITouch.Phase.ended.rawValue ||
                phase == UITouch.Phase.cancelled.rawValue)
    }
    
    public init(_ menuKey: Int,
                _ cornerStr: String,
                _ nodeType: MuNodeType,
                _ hashPath: [Int],
                _ point: CGPoint,
                _ phase: UITouch.Phase) {
        
        self.menuKey = menuKey
        self.cornerStr = cornerStr
        self.type = nodeType.rawValue
        self.hashPath = hashPath
        self.time = Date().timeIntervalSince1970
        self.point = [Float(point.x), Float(point.y)]
        self.phase = phase.rawValue
    }
    public init(_ menuKey: Int,
                _ cornerStr: String,
                _ nodeType: MuNodeType,
                _ hashPath: [Int],
                _ thumb: [Double],
                _ phase: UITouch.Phase) {

        self.menuKey = menuKey
        self.cornerStr = cornerStr
        self.type = nodeType.rawValue
        self.hashPath = hashPath
        self.time = Date().timeIntervalSince1970
        self.point = [Float(thumb[0]), Float(thumb[1])]
        self.phase = phase.rawValue
    }
    enum CodingKeys: String, CodingKey {
        case menuKey, cornerStr, type, time, hashPath, point, phase }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try menuKey   = container.decode(Int     .self , forKey: .menuKey   )
        try type      = container.decode(String  .self , forKey: .type      )
        try cornerStr = container.decode(String  .self , forKey: .cornerStr )
        try time      = container.decode(Double  .self , forKey: .time      )
        try hashPath  = container.decode([Int]   .self , forKey: .hashPath  )
        try point     = container.decode([Float] .self , forKey: .point     )
        try phase     = container.decode(Int     .self , forKey: .phase     )
    }
}
