//  created by musesum on 12/1/22.

import SwiftUI
import MuFlo
import MuVision

#if os(visionOS)
import _CompositorServices_SwiftUI
#endif
public protocol MenuDelegate {
    func window(frame: CGRect, insets: EdgeInsets)
}

public struct MenuView: View {

    #if os(visionOS)
    @State private var immersiveSpaceIsShown = false //...

    #endif

    var menuVms: [MenuVm]
    var touchVms: [TouchVm] { menuVms.map { $0.rootVm.touchVm } }
    var touchesView: TouchesView
    var delegate: MenuDelegate
    //???? @ObservedObject var renderState: RenderState

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
                    .ignoresSafeArea()
                
                ForEach(menuVms, id: \.self) { menuVm in
                    MenuTouchView(menuVm: menuVm).ignoresSafeArea()
                }
            }
            .onAppear {
                delegate.window(frame: geo.frame(in: .global), insets: geo.safeAreaInsets)
            }

            #if os(visionOS)
            .onChange(of: geo.frame(in: .global)) { old, now in
                delegate.window(frame: now, insets: geo.safeAreaInsets)
                //???? print("frame old\(old.script) now\(now.script)")
            }
            #else
            .onChange(of: geo.frame(in: .global)) {
                delegate.window(frame: $0, insets: geo.safeAreaInsets) }
            #endif
            .statusBar(hidden: true)
        }
    }
}
