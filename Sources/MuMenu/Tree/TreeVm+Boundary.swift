// created by musesum on 6/15/25

import SwiftUI
import MuFlo
import MuVision

extension TreeVm { // + Boundary

    func bounded(from: RangeXY) -> CGFloat {
        switch menuType.progression {
        case .VW: return from.0.lowerBound
        case .VE: return from.0.upperBound
        case .HN: return from.1.lowerBound
        case .HS: return from.1.upperBound
        }
    }

    func outerLimit(of range: RangeXY) -> CGSize {
        let x: CGFloat
        let y: CGFloat
        switch menuType.progression  {
        case .VW: x = range.0.lowerBound; y = 0
        case .VE: x = range.0.upperBound; y = 0
        case .HN: x = 0 ; y = range.1.lowerBound
        case .HS: x = 0 ; y = range.1.upperBound
        }
        return CGSize(width: x, height: y)
    }
}

