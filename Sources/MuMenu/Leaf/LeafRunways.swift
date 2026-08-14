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
@MainActor
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

    /// xyzw pads host two thumbs: runXY (x,y) and runWZ (w in x-slot,
    /// z in y-slot). `activePad` is the filled thumb the pad drags;
    /// the other renders as a dotted outline and taps swap the roles.
    var hasWZ: Bool { runwayThumbs[.runWZ] != nil }
    public private(set) var activePad: LeafRunwayType = .runXY

    /// runWZ shares the runXY pad bounds — it never registers its own
    private func boundsKey(_ type: LeafRunwayType) -> LeafRunwayType {
        type == .runWZ ? .runXY : type
    }

    init(_ panelVm: PanelVm, _ runTypes: [LeafRunwayType]) {
        self.panelVm = panelVm
        for runType in runTypes {
            runwayThumbs[runType] = LeafThumb(runType)
        }
    }
    /// runway of the current/last touch — LeafXyzwVm scopes user fires to it
    func touchType() -> LeafRunwayType { runwayType }
    /// remote leaf items carry their thumb's runway; align before syncVal
    func setTouchType(_ type: LeafRunwayType) { runwayType = type }

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
        return runwayBounds[boundsKey(type)]
    }

    var thumbNormRadius: Double {
        if let bounds = runwayBounds[boundsKey(runwayType)]  {
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
        let vw = exprs.normalize("w", .value)
        let tx = exprs.normalize("x", .tween)
        let ty = exprs.normalize("y", .tween)
        let tz = exprs.normalize("z", .tween)
        let tw = exprs.normalize("w", .tween)

        // dispatch found values to each runway thumb
        for (type,thumb) in runwayThumbs {
            switch type { //  eligible          ___values___    ___tweens___
            case .runX  : thumb.setValueTween( vx, nil, nil,   tx, nil, nil)
            case .runY  : thumb.setValueTween(nil,  vy, nil,  nil,  ty, nil)
            case .runZ  : thumb.setValueTween(nil, nil, vz,   nil, nil,  tz)
            case .runW  : thumb.setValueTween( vw, nil, nil,   tw, nil, nil) // w rides the x-slot of its own thumb
            case .runWZ : thumb.setValueTween( vw,  vz, nil,   tw,  tz, nil) // pad thumb: w in x-slot, z in y-slot
            case .runXY : thumb.setValueTween( vx,  vy,  vz,   tx,  ty,  tz) // z rides along: syncVal reads z from this thumb
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
        if hasWZ {
            return setThumbPointWZ(normPoint, type, offsetting)
        }
        var x: Double?
        var y: Double?
        var z: Double?
        switch self.runwayType {
        case .runX   : x = normPoint.x
        case .runY   : y = normPoint.y
        case .runZ   : z = normPoint.z
        case .runW   : x = normPoint.x // w is horizontal; rides the x-slot of the runW thumb only
        case .runXY  : x = normPoint.x ; y = normPoint.y
        case .runVal : x = normPoint.x ; y = normPoint.y
        default: break
        }

        for (thumbType, thumb) in runwayThumbs {
            // w isolation: the runW thumb stores w in its x-slot, so x/y/z/xy
            // touches must never write it, and a w touch writes only it
            if (thumbType == .runW) != (type == .runW) { continue }
            switch type { // where user is touching leaf
            case .runX   : thumb.setValue( x,  nil, nil, offsetting)
            case .runY   : thumb.setValue(nil,   y, nil, offsetting)
            case .runZ   : thumb.setValue(nil, nil,   z, offsetting)
            case .runW   : thumb.setValue( x,  nil, nil, offsetting)
            case .runXY  : thumb.setValue(  x,   y, nil, offsetting)
            case .runVal : (panelVm.menuType.vertical
                            ? thumb.setValue(nil,   y, nil, offsetting)
                            : thumb.setValue( x,  nil, nil, offsetting))
            default: break
            }
        }
    }

    /// xyzw dispatch: {x, y, xy} and {z, w, wz} groups isolate from each
    /// other; the runWZ pad thumb mirrors w in its x-slot, z in its y-slot
    private func setThumbPointWZ(_ norm: SIMD3<Double>,
                                 _ type: LeafRunwayType,
                                 _ offsetting: Offsetting) {
        switch type {
        case .runX:
            thumb(.runX)? .setValue(norm.x, nil, nil, offsetting)
            thumb(.runXY)?.setValue(norm.x, nil, nil, offsetting)
        case .runY:
            thumb(.runY)? .setValue(nil, norm.y, nil, offsetting)
            thumb(.runXY)?.setValue(nil, norm.y, nil, offsetting)
        case .runXY:
            thumb(.runX)? .setValue(norm.x, nil, nil, offsetting)
            thumb(.runY)? .setValue(nil, norm.y, nil, offsetting)
            thumb(.runXY)?.setValue(norm.x, norm.y, nil, offsetting)
        case .runZ: // vertical bezel: z arrives in norm.z
            thumb(.runZ)? .setValue(nil, nil, norm.z, offsetting)
            thumb(.runWZ)?.setValue(nil, norm.z, nil, offsetting)
        case .runW: // horizontal bezel: w arrives in norm.x
            thumb(.runW)? .setValue(norm.x, nil, nil, offsetting)
            thumb(.runWZ)?.setValue(norm.x, nil, nil, offsetting)
        case .runWZ: // pad drag: w horizontal, z vertical
            thumb(.runWZ)?.setValue(norm.x, norm.y, nil, offsetting)
            thumb(.runW)? .setValue(norm.x, nil, nil, offsetting)
            thumb(.runZ)? .setValue(nil, nil, norm.y, offsetting)
        default: break
        }
    }

    /// updated by View after auto-layout
    func updateBounds(_ type: LeafRunwayType,
                      _ bounds: CGRect) {
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
        case .runX,.runY,.runZ,.runW : return Double(Menu.radius / 2 - 1)
        default                : return Double(Menu.radius - 1)
        }
    }
    /// circular hit-test centered on the VISUAL thumb: value 0…1 maps into
    /// the radius-inset runway (inverse of normalizePoint), center-anchored —
    /// the previous top-left-anchored rect missed the thumb by a full radius
    public func thumb(_ type: LeafRunwayType, contains point: CGPoint) -> Bool {
        guard let thumb = thumb(type) ,
              let bounds = bounds(type) else { return false } // runWZ falls back to the shared pad bounds
        let radius = thumbRadius(type)
        // slider thumbs are sub-finger (radius 9 inside a 20pt bezel):
        // grab with a finger-sized circle so catch-up drag engages —
        // position math below still uses the true radius inset
        let grabRadius: Double
        switch type {
        case .runX, .runY, .runZ, .runW : grabRadius = max(radius, Double(Menu.radius))
        default                         : grabRadius = radius
        }
        let xMax = max(radius, Double(bounds.width)  - radius)
        let yMax = max(radius, Double(bounds.height) - radius)
        let vx: Double? // value slot driving each axis; nil = centered cross-axis
        let vy: Double?
        switch type {
        case .runX, .runW : vx = thumb.value.x ; vy = nil               // horizontal sliders
        case .runY        : vx = nil           ; vy = thumb.value.y     // vertical sliders
        case .runZ        : vx = nil           ; vy = thumb.value.z
        default           : vx = thumb.value.x ; vy = thumb.value.y     // pads (runWZ: x=w, y=z)
        }
        let cx = vx == nil ? Double(bounds.midX)
                           : Double(bounds.minX) + radius + vx!.clamped(to: 0...1) * (xMax - radius)
        let cy = vy == nil ? Double(bounds.midY)
                           : Double(bounds.minY) + radius + (1 - vy!.clamped(to: 0...1)) * (yMax - radius)
        let dx = Double(point.x) - cx
        let dy = Double(point.y) - cy
        return dx * dx + dy * dy <= grabRadius * grabRadius
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
        case .runW: norm = SIMD3<Double>(xn,  0,  0) // horizontal like runX
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
        // Use panelVm natural dimensions — stored bounds may be in visual (post-scaleEffect)
        // space on watchOS, which would make the centering offsets ~3× too large.
        let thumbR = (type.thumbRadius - 2.0) / 2.0
        let nat    = panelVm.innerPanel(type)
        let bW     = Double(nat.width)
        let bH     = Double(nat.height)
        switch type {
        case .runX, .runW: // runW thumb carries w in its x-slot, horizontal like runX
            let cx = thumbR + item.x.clamped(to: 0...1) * max(0, bW - 2 * thumbR)
            return CGSize(width: cx - thumbR, height: bH / 2.0 - thumbR)
        case .runY:
            let cy = thumbR + (1 - item.y).clamped(to: 0...1) * max(0, bH - 2 * thumbR)
            return CGSize(width: bW / 2.0 - thumbR, height: cy - thumbR)
        case .runZ:
            let cy = thumbR + (1 - item.z).clamped(to: 0...1) * max(0, bH - 2 * thumbR)
            return CGSize(width: bW / 2.0 - thumbR, height: cy - thumbR)
        default:
            let cx = thumbR + item.x.clamped(to: 0...1) * max(0, bW - 2 * thumbR)
            let cy = thumbR + (1 - item.y).clamped(to: 0...1) * max(0, bH - 2 * thumbR)
            return CGSize(width: cx - thumbR, height: cy - thumbR)
        }
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
            if let (type, bounds) = hitRunway() {
                var type = type
                if hasWZ {
                    // dragging x/y/xy fills the XY thumb; z/w/wz fills WZ.
                    // a pad tap on the uncovered dotted thumb swaps roles
                    switch type {
                    case .runX, .runY : activePad = .runXY
                    case .runZ, .runW : activePad = .runWZ
                    case .runXY:
                        let dotted: LeafRunwayType = (activePad == .runXY) ? .runWZ : .runXY
                        if !thumb(activePad, contains: point),
                           thumb(dotted, contains: point) {
                            activePad = dotted
                        }
                        type = activePad
                    default: break
                    }
                }
                self.runwayType = type
                setThumbPoint(point, runwayType, bounds, quantize, newOffset: true)
            } else {
                print ("[.none]")
            }
        }
        /// exact bounds first (pads keep priority at shared edges); then a
        /// forgiving pass for the thin slider bezels — their 20pt strips are
        /// sub-finger, so outset them by Menu.radius and take the nearest
        func hitRunway() -> (LeafRunwayType, CGRect)? {
            for (type, bounds) in runwayBounds {
                if bounds.contains(point) { return (type, bounds) }
            }
            let sliders: Set<LeafRunwayType> = [.runX, .runY, .runZ, .runW]
            var nearest: (LeafRunwayType, CGRect)?
            var nearestDist = Double.infinity
            for (type, bounds) in runwayBounds where sliders.contains(type) {
                let outset = bounds.insetBy(dx: -Menu.radius, dy: -Menu.radius)
                if outset.contains(point) {
                    let dx = Double(point.x - bounds.midX)
                    let dy = Double(point.y - bounds.midY)
                    let dist = dx * dx + dy * dy
                    if dist < nearestDist {
                        nearestDist = dist
                        nearest = (type, bounds)
                    }
                }
            }
            return nearest
        }
        /// continue moving current thumb & runway
        func nextRunway() {
            if let bounds = runwayBounds[boundsKey(runwayType)]  {
                setThumbPoint(point, runwayType, bounds, quantize, newOffset: false)
            }
        }
    }
}

