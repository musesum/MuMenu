// created by musesum on 2/27/25


import Foundation
import SwiftUI
import MuFlo

/// thumb values are normalized to 0...1
public class LeafThumb: Codable {

    var value: SIMD3<Double> = .zero /// destination value
    var tween: SIMD3<Double> = .zero /// current tween value
    var offset: SIMD3<Double> = .zero /// touch offset from center
    var type: LeafRunwayType = .none

    /// offset was previously called "delta" for a touch
    /// inside an xy thumb, but not perfectly cnetered,
    /// to prevent any shifting of center during touchBegin.
    /// During subsequent touchMove, the delta decreases
    /// shifting the center to under the touch point.

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
    
    func setValueTween(_ vx: Double? = nil,
                       _ vy: Double? = nil,
                       _ vz: Double? = nil,
                       _ tx: Double? = nil,
                       _ ty: Double? = nil,
                       _ tz: Double? = nil) {

        value.x = vx ?? value.x
        value.y = vy ?? value.y
        value.z = vz ?? value.z

        tween.x = tx ?? tween.x
        tween.y = ty ?? tween.y
        tween.z = tz ?? tween.z
    }


    func setValue(_ x: Double? = nil,
                  _ y: Double? = nil,
                  _ z: Double? = nil,
                  _ offsetting: Offsetting) {

        switch offsetting {
        case .none:
            if let x { value.x = x.clamped(to: 0...1) }
            if let y { value.y = y.clamped(to: 0...1) }
            if let z { value.z = z.clamped(to: 0...1) }
            offset = .zero

        case .begin:
            if let x { offset.x = (x - value.x).clamped(to: 0...1) } else { offset.x = 0 }
            if let y { offset.y = (y - value.y).clamped(to: 0...1) } else { offset.y = 0 }
            if let z { offset.z = (z - value.z).clamped(to: 0...1) } else { offset.z = 0 }

        case .move:
            if let x { value.x = (x - offset.x).clamped(to: 0...1) }
            if let y { value.y = (y - offset.y).clamped(to: 0...1) }
            if let z { value.z = (z - offset.z).clamped(to: 0...1) }
            offset *= 0.88 // reduce downto zero

        }
    }

}
