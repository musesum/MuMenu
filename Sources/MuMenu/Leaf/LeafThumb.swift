// created by musesum on 2/27/25


import Foundation
import SwiftUI
import MuFlo

/// thumb values are normalized to 0...1
@MainActor
public class LeafThumb: ObservableObject, @preconcurrency Codable {

    var value: SIMD3<Double> = .zero /// destination value
    var tween: SIMD3<Double> = .zero /// current tween value
    var offset: SIMD3<Double> = .zero /// touch offset from center
    var type: LeafRunwayType = .none

    /// bias was previously called "delta" for a touch
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
    enum CodingKeys: String, CodingKey {
        case valueX, valueY, valueZ
        case tweenX, tweenY, tweenZ
        case offsetX, offsetY, offsetZ
        case type
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let vx = try container.decode(Double.self, forKey: .valueX)
        let vy = try container.decode(Double.self, forKey: .valueY)
        let vz = try container.decode(Double.self, forKey: .valueZ)
        value = SIMD3(vx, vy, vz)

        let tx = try container.decode(Double.self, forKey: .tweenX)
        let ty = try container.decode(Double.self, forKey: .tweenY)
        let tz = try container.decode(Double.self, forKey: .tweenZ)
        tween = SIMD3(tx, ty, tz)

        let ox = try container.decode(Double.self, forKey: .offsetX)
        let oy = try container.decode(Double.self, forKey: .offsetY)
        let oz = try container.decode(Double.self, forKey: .offsetZ)
        offset = SIMD3(ox, oy, oz)

        type = try container.decode(LeafRunwayType.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(value.x, forKey: .valueX)
        try container.encode(value.y, forKey: .valueY)
        try container.encode(value.z, forKey: .valueZ)

        try container.encode(tween.x, forKey: .tweenX)
        try container.encode(tween.y, forKey: .tweenY)
        try container.encode(tween.z, forKey: .tweenZ)

        try container.encode(offset.x, forKey: .offsetX)
        try container.encode(offset.y, forKey: .offsetY)
        try container.encode(offset.z, forKey: .offsetZ)

        try container.encode(type, forKey: .type)
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
            if let x { value.x = x }
            if let y { value.y = y }
            if let z { value.z = z }
            offset = .zero

        case .begin:
            if let x { offset.x = x - value.x } else {  offset.x = 0 }
            if let y { offset.y = y - value.y } else {  offset.y = 0 }
            if let z { offset.z = z - value.z } else {  offset.z = 0 }

        case .move:
            if let x { value.x = x - offset.x }
            if let y { value.y = y - offset.y }
            if let z { value.z = z - offset.z }
            offset *= 0.88 // reduce downto zero

        }
    }

}
