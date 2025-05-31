//  created by musesum on 1/3/23.

import UIKit

public struct MenuTouchItem: Codable {

    public let touch: [Double]
    public let finger: Int

    public init(_ touch: UITouch) {
        self.touch = touch.location(in: nil).doubles()
        self.finger = touch.hash
    }
    public var cgPoint: CGPoint { CGPoint(x: touch[0], y: touch[1]) }
}

