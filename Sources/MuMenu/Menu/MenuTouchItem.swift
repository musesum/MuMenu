//  Created by warren on 1/3/23.

import UIKit

public struct MenuTouchItem: Codable {

    public let touch: [Double]

    public init(_ touch: UITouch) {
        self.touch = touch.location(in: nil).doubles()
    }

    enum CodingKeys: String, CodingKey {
        case touch }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        try touch = container.decode([Double].self, forKey: .touch    )
    }
    public var cgPoint: CGPoint { CGPoint(x: touch[0], y: touch[1]) }
}

