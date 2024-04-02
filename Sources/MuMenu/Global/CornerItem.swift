//  created by musesum on 1/1/23.

import SwiftUI
import MuExtensions

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

public enum SideAxis: Int {
    case LeftH,LeftV,RightH,RightV

    init(_ cornerOp: CornerOp,_ axis: Axis) {
        self = (cornerOp.left
                ? axis == .horizontal ? .LeftH : .LeftV
                : axis == .horizontal ? .RightH : .RightV )

    }

}


public enum CornerAxis: Int {
    case LLH,LLV,ULH,ULV,LRH,LRV,URH,URV

    init(_ corner: CornerOp,_ axis: Axis) {
        switch (corner, axis) {
        case ([.lower, .left], .horizontal): self = .LLH
        case ([.lower, .left], .vertical  ): self = .LLV
        case ([.lower,.right], .horizontal): self = .LRH
        case ([.lower,.right], .vertical  ): self = .LRV
        case ([.upper, .left], .horizontal): self = .ULH
        case ([.upper, .left], .vertical  ): self = .ULV
        case ([.upper,.right], .horizontal): self = .URH
        case ([.upper,.right], .vertical  ): self = .URV
        default: self = .LLV
        }
    }
}
public struct CornerItem {

    public let corner: CornerOp
    public let axis: Axis
    public let key: String

    let bound: CornerBound
    var depth = Axii(h:0, v:0)
    var start = Axii(h:0, v:0)
    let cornerAxis: CornerAxis
    let sideAxis: SideAxis

    public init(_ corner: CornerOp,
                _ axis: Axis,
                _ key: String) {
        self.corner = corner
        self.axis = axis
        self.key = key

        self.bound = (axis == .vertical
                      ? (corner.left  ? .lowX : .uprX)
                      : (corner.upper ? .lowY : .uprY))
        self.cornerAxis = CornerAxis(corner, axis)
        self.sideAxis = SideAxis(corner, axis)
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
