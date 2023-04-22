//  Created by warren on 12/1/22.

import SwiftUI
import MuFlo

public struct MenuView: View {

    var menuVms: [MenuVm]
    var touchVms: [MuTouchVm] { menuVms.map { $0.rootVm.touchVm } }
    var touchView: TouchView
    
    public init(_ root: Flo,
                _ touchView: TouchView) {
        self.menuVms = MenuVms(root).menuVms
        self.touchView = touchView
    }
    public init(_ touchView: TouchView,
                _ menuVms: [MenuVm]) {
        self.menuVms = menuVms
        self.touchView = touchView
    }
    public var body: some View {

        ZStack(alignment: .bottomLeading) {

            TouchViewRepresentable(touchVms, touchView)
            ForEach(menuVms, id: \.self) { menuVm in
                MenuTouchView(menuVm: menuVm)
            }
        }
        .statusBar(hidden: true)
    }
}
