//  created by musesum on 12/1/22.

import SwiftUI
import MuFlo
import MuPeers

public protocol MenuRect {
    func menuRect(_ frame: CGRect,  _ insets: EdgeInsets, onAppear: Bool)
}

public struct MenuView: View {

    static var menuRect: MenuRect?

    var menuVms: [MenuVm]
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    
    public init(_ root: Flo,
                _ archiveVm: ArchiveVm,
                _ peers: Peers,
                _ menuRect: MenuRect) {

        self.menuVms = MenuVms(root, archiveVm, peers).menuVms
        MenuView.menuRect = menuRect
    }

    public init(_ menuVms: [MenuVm],
                _ menuRect: MenuRect) {

        self.menuVms = menuVms
        MenuView.menuRect = menuRect
    }
    func geoFrame(_ geo: GeometryProxy, onAppear: Bool) {

        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        if let menuRect = MenuView.menuRect {
            menuRect.menuRect(frame, insets, onAppear: onAppear)
        }
    }
    public var body: some View {

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(menuVms, id: \.self) { menuVm in
                    MenuRootView(menuVm: menuVm)
                }
            }
            .background(.clear)
            .onAppear { geoFrame(geo, onAppear: true) }
            .onChange(of: geo.frame(in: .global)) { geoFrame(geo, onAppear: false) }
            .statusBar(hidden: true)
        }
    }
}
