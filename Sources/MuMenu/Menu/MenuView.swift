//  Created by warren on 12/1/22.

import SwiftUI
import MuFlo


public protocol MenuDelegate {
    func window(bounds: CGRect)
}

public struct MenuView: View {

    var menuVms: [MenuVm]
    var touchVms: [MuTouchVm] { menuVms.map { $0.rootVm.touchVm } }
    var touchView: TouchView
    var delegate: MenuDelegate

    public init(_ root: Flo,
                _ touchView: TouchView,
                _ delegate: MenuDelegate) {

        self.menuVms = MenuVms(root).menuVms
        self.touchView = touchView
        self.delegate = delegate
    }
    public init(_ touchView: TouchView,
                _ menuVms: [MenuVm],
                _ delegate: MenuDelegate) {
        self.menuVms = menuVms
        self.touchView = touchView
        self.delegate = delegate
    }
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {

                TouchViewRepresentable(touchVms, touchView)
                ForEach(menuVms, id: \.self) { menuVm in
                    MenuTouchView(menuVm: menuVm)
                }
            }
            .onAppear { delegate.window(bounds: geo.frame(in: .global)) }
            .onChange(of: geo.frame(in: .global)) { delegate.window(bounds: $0) }

            .statusBar(hidden: true)
        }
    }
}
