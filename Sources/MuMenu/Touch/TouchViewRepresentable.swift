//  created by musesum on 12/11/22.

import SwiftUI

struct TouchViewRepresentable: UIViewRepresentable {

    typealias Context = UIViewRepresentableContext<TouchViewRepresentable>
    var touchVms: [TouchVm]
    var touchView: TouchesView

    public init(_ touchVms: [TouchVm],
                _ touchView: TouchesView) {

        self.touchVms = touchVms
        self.touchView = touchView
        for touchVm in touchVms {
            CornerTouchVm[touchVm.corner.rawValue] = touchVm
        }
    }
    public func makeUIView(context: Context) -> TouchesView {
        return touchView
    }
    public func updateUIView(_ uiView: TouchesView, context: Context) {
        //print("updateUIView", terminator: " ")
    }
}
