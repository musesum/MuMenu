//  created by musesum on 12/1/22.

import SwiftUI
import MuFlo

public protocol MenuDelegate {
    func window(frame: CGRect, insets: EdgeInsets)
}

public struct MenuView: View {

    var menuVms: [MenuVm]
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    var delegate: MenuDelegate

    public init(_ root: Flo,
                _ delegate: MenuDelegate) {

        self.menuVms = MenuVms(root).menuVms
        self.delegate = delegate
    }

    public init(_ menuVms     : [MenuVm],
                _ delegate    : MenuDelegate) {

        self.menuVms = menuVms
        self.delegate = delegate
    }

    public var body: some View {

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
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
