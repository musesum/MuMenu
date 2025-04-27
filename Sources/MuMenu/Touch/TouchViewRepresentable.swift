//  created by musesum on 12/11/22.

import SwiftUI
import MuFlo

public struct TouchViewRepresentable: UIViewRepresentable {

    public typealias Context = UIViewRepresentableContext<TouchViewRepresentable>
    public static var aspect: Aspect = .square
    public static var callAspects = [CallAspect]()

    var cornerVms: [CornerVm]
    var touchView: TouchView

    public init(_ menuVms: [MenuVm],
                _ touchView: TouchView) {

        self.cornerVms = menuVms.map { $0.rootVm.cornerVm }
        self.touchView = touchView
        touchView.translatesAutoresizingMaskIntoConstraints = true
        for cornerVm in cornerVms {
            CornerOpVm[cornerVm.corner.rawValue] = cornerVm
        }
    }
    public func makeUIView(context: Context) -> TouchView {
        touchView.translatesAutoresizingMaskIntoConstraints = true
        return touchView
    }
    public func updateUIView(_ touchView: TouchView, context: Context) {
        let aspect = touchView.frame.size.aspect
        TouchViewRepresentable.aspect = aspect
        for callAspect in TouchViewRepresentable.callAspects {
            callAspect(aspect)
        }
        DebugLog { P("📋 updateUIView touchView\(touchView.frame.digits(0))") }
    }

}
