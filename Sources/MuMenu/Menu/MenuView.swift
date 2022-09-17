//  Created by warren on 6/11/22.


import SwiftUI

public struct MenuDragView: View {

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
                    .frame(width: geo.size.width, height: 18, alignment: .top)

                MuRootView()
                    .environmentObject(menuVm.rootVm)
                    .onAppear() { menuVm.rootVm.touchVm.updateBounds(geo.frame(in: .global)) }
                // gestures provided by Drag
                    .allowsHitTesting(true)
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .updating($touchXY) { (value, touchXY, _) in
                            touchXY = value.location })
                    .onChange(of: touchXY) { menuVm.rootVm.touchVm.touchMenuUpdate($0) }
                // .defersSystemGestures(on: .vertical)
            }
        }
    }
}

/// UIKit UITouch replaces drag
public struct MenuView: View {

    let menuVm: MenuVm
    let statusVm = MuStatusVm.shared

    public init(menuVm: MenuVm) {
        self.menuVm = menuVm
    }
    public var body: some View {
        ZStack {
            GeometryReader { geo in
                MuStatusView()
                    .frame(width: geo.size.width, height: 18, alignment: .top)
                MuRootView()
                    .environmentObject(menuVm.rootVm)
                    .onAppear() { menuVm.rootVm.touchVm.updateBounds(geo.frame(in: .global)) }
                // gestures provided by UITouch
                    .allowsHitTesting(false)
            }
        }
    }
}
