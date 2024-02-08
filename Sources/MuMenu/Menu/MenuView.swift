//  created by musesum on 12/1/22.

import SwiftUI
import MuFlo
import MuExtensions

public protocol MenuDelegate {
    func window(frame: CGRect, insets: EdgeInsets)
}

public struct MenuView: View {

    var menuVms: [MenuVm]
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    var touchesView: TouchesView
    var delegate: MenuDelegate

    public init(_ root: Flo,
                _ touchesView: TouchesView,
                _ delegate: MenuDelegate) {

        self.menuVms = MenuVms(root).menuVms
        self.touchesView = touchesView
        self.delegate = delegate
    }
    public init(_ touchesView : TouchesView,
                _ menuVms     : [MenuVm],
                _ delegate    : MenuDelegate) {

        self.menuVms = menuVms
        self.touchesView = touchesView
        self.delegate = delegate
    }

    public var body: some View {

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                TouchViewRepresentable(cornerVms, touchesView)

                ForEach(menuVms, id: \.self) { menuVm in
                    MenuDragView(menuVm: menuVm)
                }
            }
            .onAppear {
                delegate.window(frame: geo.frame(in: .global), insets:  geo.safeAreaInsets) }
            #if os(visionOS)
            .onChange(of: geo.frame(in: .global)) { old, now in
                delegate.window(frame: now, insets: geo.safeAreaInsets)
            }
            #else
            .onChange(of: geo.frame(in: .global)) {
                delegate.window(frame: $0, insets: geo.safeAreaInsets) }
            #endif
            .statusBar(hidden: true)
        }
    }
}
