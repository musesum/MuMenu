//  created by musesum on 1/3/23.

import UIKit
import MuFlo

public struct MenuTouchItem: Codable, Sendable {

    public let touch: [Double]
    public let finger: Int

    public init(_ touch: SendTouch) {
        self.touch = touch.nextXY.doubles()
        self.finger = touch.hash
    }

    enum CodingKeys: String, CodingKey {
        case touch, finger }

    nonisolated public init(from decoder: Decoder) throws {
        let c  = try decoder.container(keyedBy: CodingKeys.self)
        try touch  = c.decode([Double].self, forKey: .touch  )
        try finger = c.decode(Int     .self, forKey: .finger )
    }
    public var cgPoint: CGPoint { CGPoint(x: touch[0], y: touch[1]) }
}

