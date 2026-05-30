// created by musesum on 2/27/25


import Foundation
import SwiftUI
import MuFlo

public enum LeafRunwayType: String, Codable {
    case none   = "none"
    case runX   = "x"
    case runY   = "y"
    case runU   = "u"
    case runV   = "v"
    case runW   = "w"
    case runZ   = "z"
    case runS   = "s"
    case runT   = "t"
    case runXY  = "xy"
    case runWZ  = "wz"
    case runUV  = "uv"
    case runST  = "st"
    case runVal = "val"

    var thumbRadius: Double {
        #if os(watchOS)
        // Scale thumbs down ~3× on watchOS so they fit inside the rescaled
        // iOS LeafBezelView geometry (Menu.diameter is 13 vs iOS 40).
        switch self {
        case .runX, .runY, .runU, .runV, .runW, .runZ, .runS, .runT: 7
        default: 12
        }
        #else
        switch self {
        case .runX, .runY, .runU, .runV, .runW, .runZ, .runS, .runT: 20
        default: 40
        }
        #endif
    }
    func offset(_ point: CGPoint,_ bounds: CGRect) -> SIMD2<Double> {
        var offset = SIMD2<Double>(point - bounds.origin)
        switch self {
        case .runX, .runU, .runW, .runS: offset.y = 0
        case .runY, .runV, .runZ, .runT: offset.x = 0
        default: break
        }
        return offset
    }
}
