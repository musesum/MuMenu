//  created by musesum on 12/11/22.

import SwiftUI
import MuFlo

public struct TouchViewRepresentable: UIViewRepresentable {

    public typealias Context = UIViewRepresentableContext<TouchViewRepresentable>
    public static var aspect: Aspect = .square
    public static var callAspects = [CallAspect]()

    var menuVms: [MenuVm]
    var touchView: TouchView

    public init(_ menuVms: [MenuVm],
                _ touchView: TouchView) {

        self.menuVms = menuVms
        self.touchView = touchView
        touchView.translatesAutoresizingMaskIntoConstraints = true
        for menuVm in menuVms {
            MenuTypeCornerVm[menuVm.menuType.rawValue] = menuVm.rootVm.cornerVm
        }
        logVms()
    }
    func logVms() {
        var log = ""
        var delim = "["
        for menuVm in menuVms {
            let menuType = menuVm.menuType
            log += "\(delim)\(menuType.icon): \(menuType.rawValue)"
            delim = ", "
        }
        log += "]"
        PrintLog("MenuTypeCornerVm's \(log)")
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
        NoDebugLog { P("📋 updateUIView touchView\(touchView.frame.digits(0))") }
    }

}
