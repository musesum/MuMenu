
import SwiftUI
import MuFlo
import MuPeer
import MultipeerConnectivity


open class TouchView: UIView, UIGestureRecognizerDelegate {

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init(_ bounds: CGRect) {

        super.init(frame: .zero)
        frame = bounds
        isMultipleTouchEnabled = true
    }


    /// When starting new touch, assign finger to either Menu or Canvas.
    open func beginTouches(_ touches: Set<UITouch>) {

        for touch in touches {
            TouchMenuLocal.beginTouch(touch)
        }
    }

    /// Continue dispatching finger to canvas or menu
    open func updateTouches(_ touches: Set<UITouch>) {

        for touch in touches {
            if TouchMenuLocal.updateTouch(touch) { }
            else { print("*** unknown touch \(touch.hash)") }
        }
    }
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { beginTouches(touches) }
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
}
