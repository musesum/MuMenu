import SwiftUI
import MuFlo
import MuPeers
import MuVision
import MuHands

open class TouchView: UIView, UIGestureRecognizerDelegate {

    var safeBounds: CGRect { frame.pad(-4) }
    var touchBeganFromEdge = [Int: Bool]()
    var touchCanvas: TouchCanvas?

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init(_ pipeline: Pipeline,
                _ touchCanvas: TouchCanvas) {
        let size = pipeline.pipeSize
        NoDebugLog { P("🧭 TouchView::init size \(size.digits())") }
        super.init(frame: .zero)
        self.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.touchCanvas = touchCanvas
        self.backgroundColor = .clear
        self.isOpaque = false
        self.layer.addSublayer(pipeline.layer)
        isMultipleTouchEnabled = true
    }

    /// When starting new touch, assign finger to either Menu or Canvas.
    ///
    ///   - allow shifting menu, starting from offscreen
    ///
    open func beginTouches(_ touches: Set<UITouch>) {

        for touch in touches {
            let location = touch.location(in: nil)
            let phase = touch.phase.rawValue
            let finger = touch.hash

            if      TouchMenuLocal.beginTouch(location, phase, finger) { }
            else if willBeginFromEdge() {}
            else if let touchCanvas {

                let touchData = TouchData(
                    force    : Float(touch.force),
                    radius   : Float(touch.majorRadius),
                    nextXY   : touch.preciseLocation(in: nil),
                    phase    : touch.phase.rawValue,
                    azimuth  : touch.azimuthAngle(in: nil),
                    altitude : touch.altitudeAngle,
                    key      : touch.hash
                )
                touchCanvas.beginTouch(touchData)
            }

            func willBeginFromEdge() -> Bool {
                let touchXY = touch.preciseLocation(in: nil)
                let fromEdge = safeBounds.contains(touchXY) ? false : true
                touchBeganFromEdge[touch.hash] = fromEdge
                return fromEdge
            }
        }
    }

    /// Continue dispatching finger to canvas or menu
    open func updateTouches(_ touches: Set<UITouch>) {

        for touch in touches {

            let location = touch.location(in: nil)
            let phase = touch.phase.rawValue
            let finger = touch.hash

            if      beganFromEdge() {}
            else if TouchMenuLocal.updateTouch(location,phase,finger) { }
            else if let touchCanvas {

                let touchData = TouchData(
                    force    : Float(touch.force),
                    radius   : Float(touch.majorRadius),
                    nextXY   : touch.preciseLocation(in: nil),
                    phase    : touch.phase.rawValue,
                    azimuth  : touch.azimuthAngle(in: nil),
                    altitude : touch.altitudeAngle,
                    key      : touch.hash
                )
                touchCanvas.updateTouch(touchData) }
            else { print("👆 unknown touch \(touch.hash)") }

            func beganFromEdge() -> Bool {
                if let fromEdge = touchBeganFromEdge[finger] {
                    if touch.phase.done {
                        touchBeganFromEdge.removeValue(forKey: finger)
                    }
                    return fromEdge
                }
                return false
            }
        }
    }
    open override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) { beginTouches(touches) }
    open override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) { updateTouches(touches) }
    open override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) { updateTouches(touches) }
    open override func touchesCancelled(_ touches: Set<UITouch>, with _: UIEvent?) { updateTouches(touches) }
}
