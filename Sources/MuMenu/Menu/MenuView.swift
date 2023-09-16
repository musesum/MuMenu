//  Created by warren on 12/1/22.

import SwiftUI
import MuFlo
#if os(xrOS)
import _CompositorServices_SwiftUI
#endif
public protocol MenuDelegate {
    func window(bounds: CGRect, insets: EdgeInsets)
}

public struct MenuView: View {

    #if os(xrOS)
    @State private var enlarge = false //...
    @State private var showImmersiveSpace = false //...
    @State private var immersiveSpaceIsShown = false //...

    @Environment(\.openImmersiveSpace) var openImmersiveSpace //...
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace //...
    #endif

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
            ZStack(alignment: .topLeading) {

                TouchViewRepresentable(touchVms, touchView)
                    .background(.black)
                    .ignoresSafeArea()
                ForEach(menuVms, id: \.self) { menuVm in
                    MenuTouchView(menuVm: menuVm)
                }
            }
            .onAppear { delegate.window(bounds: geo.frame(in: .global), insets: geo.safeAreaInsets) }
            #if os(xrOS)
            .onChange(of: geo.frame(in: .global)) { old, now in delegate.window(bounds: now, insets: geo.safeAreaInsets) }
            #else
            .onChange(of: geo.frame(in: .global)) { delegate.window(bounds: $0, insets: geo.safeAreaInsets) }
            #endif
            .statusBar(hidden: true)
        }
        .background(.clear)
    }
}
