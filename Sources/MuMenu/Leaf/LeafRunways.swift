// created by musesum on 2/28/25


import Foundation
import SwiftUI
import MuFlo

/// set of thumb runways for a leaf control.
///
///     1 runway for Val, horizonal x or y
///     3 runways for Xy, includes: xy, x, y
///     4 runways for Xyz, includes: xy, x, y, z
public class LeafRunways {
    /// bounds for control surface, used to determin if touch is inside control area
    private var runwayBounds = [LeafRunwayType: CGRect]()
    private var runwayThumbs = [LeafRunwayType: LeafThumb]()
    private var runwayType = LeafRunwayType.none
    private var panelVm: PanelVm

    init(_ panelVm: PanelVm) {
        self.panelVm = panelVm
    }
    func thumb(_ type: LeafRunwayType? = nil) -> LeafThumb? {
        let type = type ?? self.runwayType
        if type != .none {
            return runwayThumbs[type]
        } else {
            return nil
        }
    }
    func bounds(_ type: LeafRunwayType? = nil) -> CGRect? {
        let type = type ?? self.runwayType
        if type != .none {
            return runwayBounds[type]
        } else {
            return nil
        }
    }

    var thumbNormRadius: Double {
        if let bounds = runwayBounds[runwayType]  {
            return runwayType.thumbRadius / max(bounds.height,bounds.width) / 2.0
        } else {
            return 1/6 //... 
        }
    }
    func updateThumb(_ type: LeafRunwayType,_ x: Double?,_ y:  Double?,_ z:  Double?) {
        if let thumb = runwayThumbs[type] {
            thumb.setValue(x,y,z)
        } else {
            let thumb = LeafThumb(type, x,y,z)
            runwayThumbs[type] = thumb
        }
    }
    /// dispatch point to thumb for each bounds
    ///
    ///     for example: Xyz control has 4 thumbs: x,y,z and xy
    ///     when touching x control, it will change both x and xy
    ///     when touching y control, it will change both y and xy
    ///     when touching z, it will change only z
    ///     when touchig xy, it will change x, y, and xy
    ///
    func setThumbs(_ point: CGPoint,
                   _ type: LeafRunwayType,
                   _ bounds: CGRect,
                   _ quantize: Double? = nil) {
        var x: Double?
        var y: Double?
        var z: Double?
        var norm = normalizePoint(point, type, bounds).clamped(to: 0...1)
        if let quantize = quantize {
            norm = norm.quantize(quantize)
        }
        switch self.runwayType {
        case .runX: x = norm.x
        case .runY: y = norm.y
        case .runZ: z = norm.z
        case .runXY: x = norm.x ; y = norm.y
        default: break
        }
        for type in runwayBounds.keys {
            /// may make a new thumb
            switch type {
            case .runX  : updateThumb(type, x,nil,nil)
            case .runY  : updateThumb(type, nil,y,nil)
            case .runZ  : updateThumb(type, nil,nil,z)
            case .runXY : updateThumb(type, x,y,nil)
            default: break
            }
        }
    }
    /// set new runway
    @discardableResult
    func beginRunway(_ point: CGPoint) -> (LeafRunwayType, LeafThumb, CGRect)? {
        for (type, bounds) in runwayBounds {
            if bounds.contains(point) {
                DebugLog { P("touchRunway \(type.rawValue)\(bounds.digits())") }
                self.runwayType = type
                setThumbs(point, type, bounds)
                if let thumb = runwayThumbs[type] {
                    return (runwayType, thumb, bounds)
                }
            }
        }
        self.runwayType = .none
        return nil
    }
    /// continue moving current thumb & runway
    @discardableResult
    func nextRunway(_ point: CGPoint, quantize: Double? = nil) -> (LeafRunwayType, LeafThumb, CGRect)? {
        if let thumb = runwayThumbs[runwayType],
           let bounds = runwayBounds[runwayType]  {
            setThumbs(point, runwayType, bounds, quantize)
            return (runwayType, thumb, bounds)
        }
        self.runwayType = .none
        return nil
    }

    /// updated by View after auto-layout
    func updateBounds(_ type: LeafRunwayType,
                      _ bounds: CGRect) {
        DebugLog { P("updateRunway \(type.rawValue)\(bounds.digits())") }
        runwayBounds[type] = bounds
        if runwayThumbs[type] == nil {
            runwayThumbs[type] = LeafThumb(type)
        }
    }
    /// does control surface contain point
    func contains(_ point: CGPoint) -> Bool {
        for bounds in runwayBounds.values {
            if bounds.contains(point) { return true }
        }
        return false
    }
    /// XY large; x,y,z ... small
    func thumbRadius(_ type: LeafRunwayType) -> Double {
        switch type {
        case .runX,.runY,.runZ : return Double(Layout.radius / 2 - 1)
        default                : return Double(Layout.radius - 1)
        }
    }

    public func thumbCenter(_ type: LeafRunwayType) -> SIMD2<Double> {
        guard let thumb = thumb(type) else { return .zero }
        guard let bounds = bounds(type) else { return .zero }
        let center = SIMD2<Double>(
            x: (  thumb.value.x) * bounds.minX + thumbRadius(type),
            y: (1-thumb.value.y) * bounds.minY + thumbRadius(type))
        DebugLog { P("thumb \(thumb.value.digits(-2)) center \(center.digits(-2))") }
        return center
    }

    func normalizePoint(_ point: CGPoint, _ type: LeafRunwayType, _ bounds: CGRect) -> SIMD3<Double> {
        let radius = thumbRadius(type)
        let x = Double(point.x - bounds.origin.x)
        let y = Double(point.y - bounds.origin.y)
        let xMax = max(radius, Double(bounds.width) - radius)
        let yMax = max(radius, Double(bounds.height) - radius)

        let xClamped = x.clamped(to: radius...xMax)
        let yClamped = y.clamped(to: radius...yMax)

        let normalizedPoint = SIMD3<Double>(
            (xClamped - radius) / (xMax - radius),
            1 - (yClamped - radius) / (yMax - radius),
            0
        )
        DebugLog { P("normalizePoint \(normalizedPoint.digits(-2)) \(type.rawValue)\(bounds.digits())") }
        return normalizedPoint
    }
    func expandThumb(_ thumb: SIMD3<Double>,
                     _ type: LeafRunwayType,
                     _ bounds: CGRect) -> CGSize {
        let radius = thumbRadius(type)
        let xMax = max(radius, Double(bounds.width) - radius)
        let yMax = max(radius, Double(bounds.height) - radius)

        // Invert the normalization:
        let xClamped =    thumb.x  * (xMax - radius)
        let yClamped = (1-thumb.y) * (yMax - radius)
        let size = CGSize(width: xClamped, height: yClamped)
        return size
    }

    /// user touch gesture inside runway
    public func touchLeaf(_ touchState: TouchState, quantize: Double? = nil) -> Bool {

        let pointNow = touchState.pointNow

        switch touchState.phase { 
        case .began:
            if touchState.touchBeginCount == 0 {
                beginRunway(pointNow)
            } else {
                // optional double tap quantize for xy control
                nextRunway(pointNow, quantize: quantize)
            }
            return true

        case .ended,.cancelled:
            return false
        default:
            nextRunway(pointNow)
            return true
        }

    }
}

