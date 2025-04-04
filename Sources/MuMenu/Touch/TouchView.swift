import SwiftUI
import MuFlo
import MuPeer
import MuVision
import MultipeerConnectivity

@MainActor
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
        DebugLog { P("🧭 TouchesView::init size \(size.digits())") }
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
    open func beginTouches(_ touches: SendTouches) {

        for touch in touches {
            //print("\(touch.phase.rawValue)",terminator: "")
            if      MenuTouchLocal.beginTouch(touch) { }
            else if willBeginFromEdge(touch) {}
            else {
                Task { await _ = touchCanvas?.beginTouch(touch) }
            }
        }
        func willBeginFromEdge(_ touch: SendTouch) -> Bool {
            let fromEdge = safeBounds.contains(touch.nextXY) ? false : true
            touchBeganFromEdge[touch.hash] = fromEdge
            return fromEdge
        }
    }

    /// Continue dispatching finger to canvas or menu
    open func updateTouches(_ touches: SendTouches) async {
        for touch in touches {
            //print("\(touch.phase.rawValue)⃝",terminator: "")
            if beganFromEdge(touch) { return }
            if let touchCanvas {
                let touched = await touchCanvas.updateTouch(touch)
                if touched { return }
                if MenuTouchLocal.updateTouch(touch) { return }
                print("👆 unknown touch \(touch.hash)")
            }
            func beganFromEdge(_ touch: SendTouch) -> Bool {
                if let fromEdge = touchBeganFromEdge[touch.hash] {
                    if touch.phase.done {
                        touchBeganFromEdge.removeValue(forKey: touch.hash)
                    }
                    return fromEdge
                }
                return false
            }
        }
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { beginTouches(SendTouches(touches)) }
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { Task { await updateTouches(SendTouches(touches)) } }
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { Task { await updateTouches(SendTouches(touches)) } }
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { Task { await updateTouches(SendTouches(touches)) } }

}
