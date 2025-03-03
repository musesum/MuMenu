// created by musesum on 2/27/25


import Foundation
import SwiftUI
import MuFlo

public class LeafThumb: Codable {
    /// normalized to 0...1
    var value: SIMD3<Double> = .zero /// destination value
    var tween: SIMD3<Double> = .zero /// current tween value
    var type: LeafRunwayType = .none

    /// bias was previously called "delta" for a touch
    /// inside an xy thumb, but not perfectly cnetered,
    /// to prevent any shifting of center during touchBegin.
    /// During subsequent touchMove, the delta decreases
    /// shifting the center to under the touch point.
    //TODO: var bias: SIMD2<Double> = .zero

    init(_ type: LeafRunwayType = .none,
         _ x: Double? = nil,
         _ y: Double? = nil,
         _ z: Double? = nil) {
        self.type = type
        if let x { value.x = x ; tween.x = x }
        if let y { value.y = y ; tween.y = y }
        if let z { value.z = z ; tween.z = z }
        self.tween = value
    }
    enum CodingKeys: String, CodingKey { case value, tween, type }

    required public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try value = c.decode(SIMD3<Double>.self, forKey: .value )
        try tween = c.decode(SIMD3<Double>.self, forKey: .tween )
        try type = c.decode(LeafRunwayType.self, forKey: .type )
    }


    // changed by type
    var thumbRadius: Double {
        switch type {
        case .runX,.runY,.runZ : Layout.radius - 1.0
        default                : (Layout.radius - 1.0) * 2.0
        }
    }

    func thumbDiameter() -> Double {
        return thumbRadius * 2
    }
    func set(x: CGFloat? = nil, y: CGFloat? = nil, z: CGFloat? = nil) {
        if let x { value.x = Double(x) }
        if let y { value.y = Double(y) }
        if let z { value.z = Double(z) }
    }
    func setValue(_ x: Double? = nil,
                  _ y: Double? = nil,
                  _ z: Double? = nil) {

        if let x { value.x = x  }
        if let y { value.y = y  }
        if let z { value.z = z  }
    }
    func set(_ point: CGPoint) {
        value = SIMD3(x: Double(point.x), y: Double(point.y), z: 0)
        tween = value
    }

}
