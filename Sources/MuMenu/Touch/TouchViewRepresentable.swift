//  created by musesum on 12/11/22.

import SwiftUI
import MuFlo

public struct TouchViewRepresentable: UIViewRepresentable {

    public typealias Context = UIViewRepresentableContext<TouchViewRepresentable>
    public static var aspect: Aspect = .square
    public static var callAspects = [CallAspect]()

    var cornerVms: [CornerVm]
    var touchesView: TouchView

    public init(_ menuVms: [MenuVm],
                _ touchesView: TouchView) {

        self.cornerVms = menuVms.map { $0.rootVm.cornerVm }
        self.touchesView = touchesView
        touchesView.translatesAutoresizingMaskIntoConstraints = true
        for cornerVm in cornerVms {
            CornerOpVm[cornerVm.cornerOp.rawValue] = cornerVm
        }
    }
    public func makeUIView(context: Context) -> TouchView {
        touchesView.translatesAutoresizingMaskIntoConstraints = true
        return touchesView
    }
    public func updateUIView(_ touchesView: TouchView, context: Context) {
        if touchesView.frame != .zero {
            let aspect = touchesView.frame.size.aspect
            TouchViewRepresentable.aspect = aspect
            for callAspect in TouchViewRepresentable.callAspects {
                callAspect(aspect)
            }
        }
        DebugLog { P("📋 updateUIView touchView\(touchesView.frame.digits(0))") }
    }

}
