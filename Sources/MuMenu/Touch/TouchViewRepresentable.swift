//  created by musesum on 12/11/22.

import SwiftUI

public struct TouchViewRepresentable: UIViewRepresentable {

    public typealias Context = UIViewRepresentableContext<TouchViewRepresentable>
    var cornerVms: [CornerVm]
    var touchesView: TouchesView

    public init(_ cornerVms: [CornerVm],
                _ touchView: TouchesView) {

        self.cornerVms = cornerVms
        self.touchesView = touchView
        for cornerVm in cornerVms {
            CornerOpVm[cornerVm.corner.rawValue] = cornerVm
        }
    }
    public func makeUIView(context: Context) -> TouchesView {
        return touchesView
    }
    public func updateUIView(_ uiView: TouchesView, context: Context) {
        //print("updateUIView", terminator: " ")
    }
}
