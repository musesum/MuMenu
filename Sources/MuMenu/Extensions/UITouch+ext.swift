import UIKit

extension UITouch.Phase {
    public func isDone() -> Bool { return self == .ended || self == .cancelled }
}

extension Int {
    func uiPhase() -> UITouch.Phase {
        switch self {
            case 0: return .began
            case 1: return .moved
            case 2: return .moved // stationary override for now
            default: return .ended
        }
    }
}
