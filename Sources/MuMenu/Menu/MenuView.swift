//  created by musesum on 12/1/22.

import SwiftUI
import MuFlo

public protocol MenuFrame {
    func menuFrame(_ frame: CGRect,  _ insets: EdgeInsets, onAppear: Bool)
}

public struct MenuView: View {

    static var menuFrames: [String: MenuFrame] = [:]

    var menuVms: [MenuVm]
    var cornerVms: [CornerVm] { menuVms.map { $0.rootVm.cornerVm } }

    public init(_ root      : Flo,
                _ menuFrame : MenuFrame) {

        self.menuVms = MenuVms(root).menuVms
        MenuView.menuFrames["MenuView"] = menuFrame
    }

    public init(_ menuVms   : [MenuVm],
                _ menuFrame : MenuFrame) {

        self.menuVms = menuVms
        MenuView.menuFrames["MenuView"] = menuFrame
    }
    func geoFrame(_ geo: GeometryProxy, onAppear: Bool) {

        let frame = geo.frame(in: .global)
        let insets = geo.safeAreaInsets
        for menuFrame in MenuView.menuFrames.values {
            menuFrame.menuFrame(frame, insets, onAppear: onAppear)
        }
    }
    public var body: some View {

        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(menuVms, id: \.self) { menuVm in
                    MenuDragView(menuVm: menuVm)
                }
            }
            .onAppear { geoFrame(geo, onAppear: true) }
            .onChange(of: geo.frame(in: .global)) { geoFrame(geo, onAppear: false) }
            .statusBar(hidden: true)
        }
    }
}
