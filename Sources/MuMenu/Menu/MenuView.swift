//  created by musesum on 12/1/22.

import SwiftUI
import MuFlo
#if !os(watchOS)
import MuPeers
#endif
@MainActor


public struct MenuView: View {

    var menuVms: [MenuVm]
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }

    public init(_ menuVms: [MenuVm]) {
        self.menuVms = menuVms
    }
    
    public var body: some View {

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(menuVms, id: \.self) { menuVm in
                    MenuRootView(menuVm: menuVm)
                }
            }
            // portrait phone only: the corner roots park at the true screen
            // corners, clear of the island, and the panels get the full width
            .frame(width: Menu.rootWidth(geo), height: Menu.rootHeight(geo))
            .offset(Menu.rootOffset(geo))
            // container truth for the panels; rotation lands here first
            .onChange(of: geo.size, initial: true) { MenuScreen.shared.post($1) }
            #if !os(watchOS)
            .statusBar(hidden: true)
            #endif
        }
    }
}
