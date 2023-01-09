//  Created by warren on 1/1/23.

import SwiftUI


struct Axii {
    var h: Int
    var v: Int
    init(h: Int,v: Int) {
        self.h = h
        self.v = v
    }
}

public enum CornerBound {
    case lowX // 1 in (1...2, 3...4)
    case uprX // 2 in (1...2, 3...4)
    case lowY // 3 in (1...2, 3...4)
    case uprY // 4 in (1...2, 3...4)
}

enum AxiMove { case root, vert, hori, canvas }

public struct CornerAxis {

    public let corner: MuCorner
    public let axis: Axis
    public let key: Int
    static func Key(_ corner: Int, _ axis: Int8) -> Int {
        (corner + 1) * (Int(axis) + 1)
    }
    let bound: CornerBound

    var depth = Axii(h:0, v:0)
    var start = Axii(h:0, v:0)

    public init(_ corner: MuCorner, _ axis: Axis) {
        self.corner = corner
        self.axis = axis
        self.key = CornerAxis.Key(corner.rawValue, axis.rawValue)

        self.bound =
        (axis == .vertical
         ? (corner.contains(.left)  ? .lowX : .uprX)
         : (corner.contains(.upper) ? .lowY : .uprY))
    }

    mutating func bounded(from: RangeXY) -> CGFloat {
        switch bound {
            case .lowX: return from.0.lowerBound
            case .uprX: return from.0.upperBound
            case .lowY: return from.1.lowerBound
            case .uprY: return from.1.upperBound
        }
    }

    mutating func outerLimit(of: RangeXY) -> CGSize {
        let x: CGFloat
        let y: CGFloat
        switch bound {
            case .lowX: x = of.0.lowerBound; y = 0
            case .uprX: x = of.0.upperBound; y = 0
            case .lowY: x = 0 ; y = of.1.lowerBound
            case .uprY: x = 0 ; y = of.1.upperBound
        }
        return CGSize(width: x, height: y)
    }

}
