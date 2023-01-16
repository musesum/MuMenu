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

public enum Cornax: Int {
    case LLH,LLV,ULH,ULV,LRH,LRV,URH,URV

    init(_ corner: MuCorner,_ axis: Axis) {
        switch (corner, axis) {
            case ([.lower, .left], .horizontal): self = Cornax.LLH
            case ([.lower, .left], .vertical  ): self = Cornax.LLV
            case ([.lower,.right], .horizontal): self = Cornax.LRH
            case ([.lower,.right], .vertical  ): self = Cornax.LRV
            case ([.upper, .left], .horizontal): self = Cornax.ULH
            case ([.upper, .left], .vertical  ): self = Cornax.ULV
            case ([.upper,.right], .horizontal): self = Cornax.URH
            case ([.upper,.right], .vertical  ): self = Cornax.URV
            default: self = .LLV
        }
    }
    var corner: MuCorner {
        switch self {
            case .LLH: return [.lower, .left]
            case .LLV: return [.lower, .left]
            case .LRH: return [.lower,.right]
            case .LRV: return [.lower,.right]
            case .ULH: return [.upper, .left]
            case .ULV: return [.upper, .left]
            case .URH: return [.upper,.right]
            case .URV: return [.upper,.right]
        }
    }
}
public struct CornerAxis {

    public let corner: MuCorner
    public let axis: Axis
    public let key: Int

    let bound: CornerBound
    var depth = Axii(h:0, v:0)
    var start = Axii(h:0, v:0)
    var cornax: Cornax = .LLV

    public init(_ corner: MuCorner, _ axis: Axis) {
        self.corner = corner
        self.axis = axis

        self.bound =
        (axis == .vertical
         ? (corner.contains(.left)  ? .lowX : .uprX)
         : (corner.contains(.upper) ? .lowY : .uprY))
        let cornax = Cornax(corner, axis)
        self.cornax = cornax
        self.key = cornax.rawValue
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
