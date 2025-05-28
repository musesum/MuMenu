//  created by musesum on 12/1/22.

import SwiftUI
import MuFlo
import MuPeers

public protocol MenuFrame {
    func menuFrame(_ frame: CGRect,  _ insets: EdgeInsets, onAppear: Bool)
}

public struct MenuView: View {

    static var menuFrame: MenuFrame?

    var menuVms: [MenuVm]
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }
    
    public init(_ root: Flo,
                _ archiveVm: ArchiveVm,
                _ peers: Peers,
                _ menuFrame: MenuFrame) {

        self.menuVms = MenuVms(root, archiveVm, peers).menuVms
        MenuView.menuFrame = menuFrame
    }

    public init(_ menuVms: [MenuVm],
                _ menuFrame: MenuFrame) {

        self.menuVms = menuVms
        MenuView.menuFrame = menuFrame
    }
    func geoFrame(_ geo: GeometryProxy, onAppear: Bool) {

        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        if let menuFrame = MenuView.menuFrame {
            menuFrame.menuFrame(frame, insets, onAppear: onAppear)
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
