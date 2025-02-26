//  created by musesum on 1/3/23.

import UIKit

public struct MenuTouchItem: Codable {

    public let touch: [Double]
    public let finger: Int

    public init(_ touch: UITouch) {
        self.touch = touch.location(in: nil).doubles()
        self.finger = touch.hash
    }

    enum CodingKeys: String, CodingKey {
        case touch, finger }

    public init(from decoder: Decoder) throws {
        let c  = try decoder.container(keyedBy: CodingKeys.self)
        try touch  = c.decode([Double].self, forKey: .touch  )
        try finger = c.decode(Int     .self, forKey: .finger )
    }
    public var cgPoint: CGPoint { CGPoint(x: touch[0], y: touch[1]) }
}

