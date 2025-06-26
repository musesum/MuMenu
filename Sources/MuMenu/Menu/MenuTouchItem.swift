//  created by musesum on 1/3/23.

import UIKit

public struct MenuTouchItem: Codable, Sendable {

    public let touch: [Double]
    public let finger: Int

    public init(_ location: CGPoint, _ hash: Int ) {
        self.touch = location.doubles()
        self.finger = hash
    }
    public var cgPoint: CGPoint { CGPoint(x: touch[0], y: touch[1]) }
}

