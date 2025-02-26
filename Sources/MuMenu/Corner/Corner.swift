// created by musesum on 11/23/24

import SwiftUI
import MuFlo
import MuVision

public struct Corner {

    let rootMenu: MenuTree
    let axis: Axis
    let chiral: Chiral
    let cornerOp: CornerOp

    let bound: CornerBound
    var depth = Axii(h:0, v:0)
    var start = Axii(h:0, v:0)
    let cornerAxis: CornerAxis
    let sideAxis: SideAxis

    public init (_ menuTree: MenuTree,
                 _ axis: Axis,
                 _ chiral: Chiral,
                 _ cornerOp: CornerOp) {

        self.rootMenu = menuTree
        self.axis     = axis
        self.chiral   = chiral
        self.cornerOp = cornerOp

        let isLeft = cornerOp.left
        let isUpper = cornerOp.upper

        self.bound = (axis == .vertical
                      ? (isLeft  ? .lowerX : .upperX)
                      : (isUpper ? .lowerY : .upperY))

        self.cornerAxis = CornerAxis(cornerOp, axis)
        self.sideAxis = SideAxis(cornerOp, axis)
    }
    mutating func bounded(from: RangeXY) -> CGFloat {
        switch bound {
        case .lowerX: return from.0.lowerBound
        case .upperX: return from.0.upperBound
        case .lowerY: return from.1.lowerBound
        case .upperY: return from.1.upperBound
        }
    }

    mutating func outerLimit(of: RangeXY) -> CGSize {
        let x: CGFloat
        let y: CGFloat
        switch bound {
        case .lowerX: x = of.0.lowerBound; y = 0
        case .upperX: x = of.0.upperBound; y = 0
        case .lowerY: x = 0 ; y = of.1.lowerBound
        case .upperY: x = 0 ; y = of.1.upperBound
        }
        return CGSize(width: x, height: y)
    }
}


struct Axii {
    var h: Int
    var v: Int
    init(h: Int,v: Int) {
        self.h = h
        self.v = v
    }
}

public enum CornerBound {
    case lowerX // 1 in (1...2, 3...4)
    case upperX // 2 in (1...2, 3...4)
    case lowerY // 3 in (1...2, 3...4)
    case upperY // 4 in (1...2, 3...4)
}

enum AxiMove { case root, vert, hori, canvas }

public enum SideAxis: Int {
    case LeftH,LeftV,RightH,RightV

    init(_ cornerOp: CornerOp, _ axis: Axis) {
        self = (cornerOp.left
                ? axis == .horizontal ? .LeftH  : .LeftV
                : axis == .horizontal ? .RightH : .RightV )
    }
}


public enum CornerAxis: Int {

    case LLH,LLV,ULH,ULV,LRH,LRV,URH,URV

    init(_ cornerOp: CornerOp, _ axis: Axis) {
       
        switch (cornerOp, axis) {
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
