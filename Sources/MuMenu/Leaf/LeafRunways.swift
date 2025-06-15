// created by musesum on 2/28/25


import Foundation
import SwiftUI
import MuFlo

/// touching inside thumb maybe off center.
/// So, instead of center jumping immediatly to new center
/// it moves toward the center, catching up
enum Offsetting { case none, begin, move }

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
    private var lastType: LeafRunwayType?

    var touchState: TouchState?
    var touching: Bool { touchState?.touching ?? false }
    var centerOffset: CGPoint = .zero

    init(_ panelVm: PanelVm, _ runTypes: [LeafRunwayType]) {
        self.panelVm = panelVm
        for runType in runTypes {
            runwayThumbs[runType] = LeafThumb(runType)
        }
    }
    func thumb(_ type: LeafRunwayType? = nil) -> LeafThumb? {
        let type = type ?? self.runwayType
        if let thumb = runwayThumbs[type] {
            return thumb
        } else {
            let thumb = LeafThumb(type)
            runwayThumbs[type] = thumb
            return thumb
        }
    }
    func bounds(_ type: LeafRunwayType? = nil) -> CGRect? {
        let type = type ?? self.runwayType
        return runwayBounds[type]
    }

    var thumbNormRadius: Double {
        if let bounds = runwayBounds[runwayType]  {
            return runwayType.thumbRadius / max(bounds.height,bounds.width) / 2.0
        } else {
            return 1/6 
        }
    }

    func setThumbFlo(_ flo: Flo) {
        guard let exprs = flo.exprs else { return }

        // values found in flo exprs normalized
        let vx = exprs.normalize("x", .value)
        let vy = exprs.normalize("y", .value)
        let vz = exprs.normalize("z", .value)
        let tx = exprs.normalize("x", .tween)
        let ty = exprs.normalize("y", .tween)
        let tz = exprs.normalize("z", .tween)

        // dispatch found values to each runway thumb
        for (type,thumb) in runwayThumbs {
            switch type { //  eligible          ___values___    ___tweens___
            case .runX  : thumb.setValueTween( vx, nil, nil,   tx, nil, nil)
            case .runY  : thumb.setValueTween(nil,  vy, nil,  nil,  ty, nil)
            case .runZ  : thumb.setValueTween(nil, nil, vz,   nil, nil,  tz)
            case .runXY : thumb.setValueTween( vx,  vy, nil,   tx,  ty, nil)
            case .none  : thumb.setValueTween( vx,  vy, vz,    tx,  ty,  tz)

            case .runVal:
                /// .runVal isVertical can set either x or y
                /// for example:  `zoom(val, x 0…1=0, ...)`
                /// even though zoom isVertical, x is vx,tx will set vy,ty
                /// will still work for`zoom(val, y 0…1=0, ...)`
                let vxy = vx ?? vy
                let vyx = vy ?? vx
                let txy = tx ?? ty
                let tyx = ty ?? tx
                thumb.setValueTween( vxy,  vyx, nil,   txy,  tyx, nil)
            default: break
            }
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
    ///     when touching val, isVertical will change x or y
    ///
    func setThumbPoint(_ point    : CGPoint,
                       _ type     : LeafRunwayType,
                       _ bounds   : CGRect,
                       _ quantize : Double? = nil,
                       newOffset  : Bool = false) {

        var normPoint = normalizePoint(point, type, bounds).clamped(to: 0...1)
        if let quantize { normPoint = normPoint.quantize(quantize) }
        let offsetting: Offsetting = (newOffset
                                      ? (thumb(type, contains: point)
                                         ? .begin
                                         : .none)
                                      : .move)
        var x: Double?
        var y: Double?
        var z: Double?
        switch self.runwayType {
        case .runX   : x = normPoint.x
        case .runY   : y = normPoint.y
        case .runZ   : z = normPoint.z
        case .runXY  : x = normPoint.x ; y = normPoint.y
        case .runVal : x = normPoint.x ; y = normPoint.y
        default: break
        }

        for thumb in runwayThumbs.values {
            switch type { // where user is touching leaf
            case .runX   : thumb.setValue( x,  nil, nil, offsetting)
            case .runY   : thumb.setValue(nil,   y, nil, offsetting)
            case .runZ   : thumb.setValue(nil, nil,   z, offsetting)
            case .runXY  : thumb.setValue(  x,   y, nil, offsetting)
            case .runVal : (panelVm.trunk.menuOp.vertical
                            ? thumb.setValue(nil,   y, nil, offsetting)
                            : thumb.setValue( x,  nil, nil, offsetting))
            default: break
            }
        }
    }

    /// updated by View after auto-layout
    func updateBounds(_ type: LeafRunwayType,
                      _ bounds: CGRect) {
        NoDebugLog { P("updateRunway \(type.rawValue)\(bounds.digits())") }
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
    public func thumb(_ type: LeafRunwayType, contains point: CGPoint) -> Bool {
        guard let thumb = thumb(type) ,
              let bounds = bounds(type) else { return false }
        let radius = thumbRadius(type)
        let x = bounds.minX +    thumb.value.x  * bounds.width
        let y = bounds.minY + (1-thumb.value.y) * bounds.height
        let rect = CGRect(x: x, y: y, width: radius*2, height: radius*2)
        let ret = rect.contains(point)
        return ret
    }
    func normalizePoint(_ point: CGPoint, _ type: LeafRunwayType, _ bounds: CGRect) -> SIMD3<Double> {
        let radius = thumbRadius(type)
        let x = Double(point.x - bounds.origin.x)
        let y = Double(point.y - bounds.origin.y)
        let xMax = max(radius, Double(bounds.width) - radius)
        let yMax = max(radius, Double(bounds.height) - radius)

        let xClamped = x.clamped(to: radius...xMax)
        let yClamped = y.clamped(to: radius...yMax)
        let xn =   (xClamped - radius) / (xMax - radius)
        let yn = 1-(yClamped - radius) / (yMax - radius)
        let norm: SIMD3<Double>
        switch type {
        case .runZ: norm = SIMD3<Double>( 0,  0, yn)
        case .runY: norm = SIMD3<Double>( 0, yn,  0)
        case .runX: norm = SIMD3<Double>(xn,  0,  0)
        default:    norm = SIMD3<Double>(xn, yn,  0)
        }
        NoDebugLog { P("normalizePoint \(norm.digits(-2)) \(type.rawValue)\(bounds.digits())") }
        return norm
    }
    func valueOffset(_ type: LeafRunwayType) -> CGSize {
        guard let thumb = thumb(type) else { return .zero }
        return expandItem(type, thumb.value)
    }
    func tweenOffset(_ type: LeafRunwayType) -> CGSize {
        guard let thumb = thumb(type) else { return .zero }
        return expandItem(type, thumb.tween)
    }
    func expandItem(_ type: LeafRunwayType, _ item: SIMD3<Double>) -> CGSize {
        guard let bounds = bounds(type) else { return .zero }
        let radius = thumbRadius(type)
        let xMax = max(radius, Double(bounds.width) - radius)
        let yMax = max(radius, Double(bounds.height) - radius)

        let x: Double
        let y: Double
        switch type {
        case .runZ: x = item.x; y = item.z
        default:    x = item.x; y = item.y
        }

        // Invert the normalization:
        let xClamped =    x  * (xMax - radius)
        let yClamped = (1-y) * (yMax - radius)
        let size = CGSize(width: xClamped, height: yClamped)
        return size
    }

    /// user touch gesture inside runway
    public func touchLeaf(_ nodeVm: NodeVm,
                          _ touchState: TouchState,
                          quantize: Double? = nil) {

        self.touchState = touchState

        let point = touchState.pointNow

        switch touchState.phase { 
        case .began:  beginRunway()
        default:      nextRunway()
        }
        /// set new runway
        func beginRunway() {
            for (type, bounds) in runwayBounds {
                if bounds.contains(point) {
                    self.runwayType = type
                    setThumbPoint(point, runwayType, bounds, quantize, newOffset: true)
                    return
                }
            }
            print ("[.none]")
        }
        /// continue moving current thumb & runway
        func nextRunway() {
            if let bounds = runwayBounds[runwayType]  {
                setThumbPoint(point, runwayType, bounds, quantize, newOffset: false)
            }
        }
    }
}

