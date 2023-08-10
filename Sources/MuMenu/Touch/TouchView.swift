
import SwiftUI
import MuFlo
import MuPeer
import MultipeerConnectivity

public protocol TouchDelegate: AnyObject {
    func drawPoint(_ point: CGPoint, _ value: CGFloat)
    func drawRadius(_ radius: CGFloat)
}

open class TouchView: UIView, UIGestureRecognizerDelegate {

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    var touchDraw: TouchDraw! // also a peers delegate

    public init(_ touchDraw: TouchDraw,
                _ bounds: CGRect) {

        super.init(frame: .zero)
        self.touchDraw = touchDraw

        //!!! let bounds = UIScreen.main.bounds
        let w = bounds.size.width
        let h = bounds.size.height
        frame = CGRect(x: 0, y: 0, width: w, height: h)
        isMultipleTouchEnabled = true
        PeersController.shared.peersDelegates.append(touchDraw)
    }
    deinit {
        PeersController.shared.remove(peersDelegate: touchDraw)
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
