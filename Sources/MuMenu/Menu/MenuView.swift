//  created by musesum on 12/1/22.

import SwiftUI
import MuFlo
#if os(visionOS)
import _CompositorServices_SwiftUI
#endif
public protocol MenuDelegate {
    func window(bounds: CGRect, insets: EdgeInsets)
}

public struct MenuView: View {

    #if os(visionOS)
    @State private var enlarge = false //...
    @State private var showImmersiveSpace = false //...
    @State private var immersiveSpaceIsShown = false //...

    @Environment(\.openImmersiveSpace) var openImmersiveSpace //...
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace //...
    #endif

    var menuVms: [MenuVm]
    var touchVms: [TouchVm] { menuVms.map { $0.rootVm.touchVm } }
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

                TouchViewRepresentable(touchVms, touchesView)
                    .background(.clear) //????
                    .ignoresSafeArea()
                #if os(visionOS)
                    .opacity(immersiveSpaceIsShown ? 0 : 1)
                #endif
                ForEach(menuVms, id: \.self) { menuVm in
                    MenuTouchView(menuVm: menuVm)
                }
                .background(.clear)
            }
            .onAppear { delegate.window(bounds: geo.frame(in: .global), insets: geo.safeAreaInsets) }
            #if os(visionOS)
            .onChange(of: geo.frame(in: .global)) { old, now in delegate.window(bounds: now, insets: geo.safeAreaInsets) }
            #else
            .onChange(of: geo.frame(in: .global)) { 
                delegate.window(bounds: $0, insets: geo.safeAreaInsets) }
            #endif
            .statusBar(hidden: true)
        }
    }
}
