//  Created by warren on 12/11/22.

import SwiftUI

struct TouchViewRepresentable: UIViewRepresentable {

    typealias Context = UIViewRepresentableContext<TouchViewRepresentable>
    var touchVms: [MuTouchVm]
    var touchView: TouchView

    public init(_ touchVms: [MuTouchVm],
                _ touchView: TouchView) {

        self.touchVms = touchVms
        self.touchView = touchView
        for touchVm in touchVms {
            CornerTouchVm[touchVm.corner.rawValue] = touchVm
        }
    }
    public func makeUIView(context: Context) -> TouchView {
        return touchView
    }
    public func updateUIView(_ uiView: TouchView, context: Context) {
        //print("updateUIView", terminator: " ")
    }
}
