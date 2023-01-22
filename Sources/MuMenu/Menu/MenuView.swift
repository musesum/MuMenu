//  Created by warren on 6/11/22.


import SwiftUI

/// SwiftUI DragGesture to navigate menu
///
public struct MenuDragView: View {

    @GestureState private var touchXY: CGPoint = .zero
    let menuVm: MenuVm

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
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .updating($touchXY) { (value, touchXY, _) in
                            touchXY = value.location })
                    .onChange(of: touchXY) { menuVm.rootVm.touchVm.updateDragXY($0) }
                    .allowsHitTesting(true) // gestures provided by DragGesture
                // .defersSystemGestures(on: .vertical)
            }
        }
    }
}

/// UIKit UITouch to navigate menu
///
/// requires a ViewController to managage view hierarcy
///
public struct MenuTouchView: View {

    let menuVm: MenuVm

    public init(menuVm: MenuVm) {
        self.menuVm = menuVm
    }
    public var body: some View {
        ZStack {
            GeometryReader { geo in
                // MuStatusView().frame(width: geo.size.width, height: 18, alignment: .top)
                MuRootView()
                    .environmentObject(menuVm.rootVm)
                    .onAppear() { menuVm.rootVm.touchVm.updateBounds(geo.frame(in: .global)) }
                    .allowsHitTesting(false) // gestures provided by UITouch
            }
        }
    }
}
