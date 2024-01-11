//  created by musesum on 4/19/23.

import SwiftUI

public struct MenuTouchView: View {

    let menuVm: MenuVm

    public init(menuVm: MenuVm) {
        self.menuVm = menuVm
    }
    public var body: some View {
        ZStack {
            GeometryReader { geo in
                // MuStatusView().frame(width: geo.size.width, height: 18, alignment: .top)
                RootView()
                    .environmentObject(menuVm.rootVm)
                    .onAppear() { menuVm.rootVm.touchVm.updateBounds(geo.frame(in: .global)) }
                    .allowsHitTesting(false) // gestures provided by UITouch
            }
        }
    }
}
