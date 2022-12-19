import UIKit

extension UITouch.Phase {
    public func isDone() -> Bool { return self == .ended || self == .cancelled }
}
