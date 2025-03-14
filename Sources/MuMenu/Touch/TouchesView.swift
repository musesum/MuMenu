import SwiftUI
import MuFlo
import MuPeer
import MuVision
import MultipeerConnectivity

open class TouchesView: UIView, UIGestureRecognizerDelegate {

    var safeBounds: CGRect { frame.pad(-4) }
    var touchBeganFromEdge = [Int: Bool]()
    var touchCanvas: TouchCanvas?

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init(_ size: CGSize,
                _ touchCanvas: TouchCanvas) {

        DebugLog { P("🧭 TouchesView::init size \(size.digits())") }
        super.init(frame: .zero)
        self.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.touchCanvas = touchCanvas
        isMultipleTouchEnabled = true
    }

    /// When starting new touch, assign finger to either Menu or Canvas.
    ///
    ///   - allow shifting menu, starting from offscreen
    ///
    open func beginTouches(_ touches: Set<UITouch>) {

        for touch in touches {
            //print("\(touch.phase.rawValue)",terminator: "")
            if      TouchMenuLocal.beginTouch(touch) { }
            else if willBeginFromEdge(touch) {}
            else if touchCanvas?.beginTouch(touch)  ?? false { }
        }
        func willBeginFromEdge(_ touch: UITouch) -> Bool {
            let touchXY = touch.preciseLocation(in: nil)
            let fromEdge = safeBounds.contains(touchXY) ? false : true
            touchBeganFromEdge[touch.hash] = fromEdge
            return fromEdge
        }
    }

    /// Continue dispatching finger to canvas or menu
    open func updateTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            //print("\(touch.phase.rawValue)⃝",terminator: "")
            if      beganFromEdge(touch) {}
            else if touchCanvas?.updateTouch(touch) ?? false { }
            else if TouchMenuLocal.updateTouch(touch) { }
            else { print("👆 unknown touch \(touch.hash)") }
        }
        func beganFromEdge(_ touch: UITouch) -> Bool {
            if let fromEdge = touchBeganFromEdge[touch.hash] {
                if touch.phase.done {
                    touchBeganFromEdge.removeValue(forKey: touch.hash)
                }
                return fromEdge
            }
            return false
        }
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { beginTouches(touches) }
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }

}
