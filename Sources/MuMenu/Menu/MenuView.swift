//  Created by warren on 6/11/22.


import SwiftUI

public struct MenuView: View {

    @GestureState private var touchXY: CGPoint = .zero
    let menuVm: MenuVm
    let statusVm = MuStatusVm.shared
    public init(menuVm: MenuVm) {
        self.menuVm = menuVm
    }
    public var body: some View {
        ZStack {
            GeometryReader { geo in
                MuStatusView()
                    .frame(width: geo.size.width,
                           height: 18,
                           alignment: .top)
            }
            MuRootView()
                .environmentObject(menuVm.rootVm)
                .coordinateSpace(name: "Canvas")
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("Canvas"))
                    .updating($touchXY) { (value, touchXY, _) in touchXY = value.location })
                .onChange(of: touchXY) { menuVm.rootVm.touchVm.touchUpdate($0) }
            //?? .defersSystemGestures(on: .vertical)
        }
    }
}
