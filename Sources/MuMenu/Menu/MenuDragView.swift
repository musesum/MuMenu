//  created by musesum on 6/11/22.


import SwiftUI

/// SwiftUI DragGesture to navigate menu

public struct MenuDragView: View {

    @GestureState private var touchXY: CGPoint = .zero
    let menuVm: MenuVm

    public init(menuVm: MenuVm) {
        self.menuVm = menuVm
    }
    public var body: some View {
        ZStack {
            GeometryReader { geo in
                StatusView()
                    .frame(width: geo.size.width, height: 18, alignment: .top)
                RootView()
                    .environmentObject(menuVm.rootVm)
                    .onAppear() { menuVm.rootVm.touchVm.updateBounds(geo.frame(in: .global)) }
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .updating($touchXY) { (value, touchXY, _) in touchXY = value.location })
                #if os(visionOS)
                    .onChange(of: touchXY) { old, now in
                        menuVm.rootVm.touchVm.updateDragXY(now)
                    }
                #else
                    .onChange(of: touchXY) {
                        menuVm.rootVm.touchVm.updateDragXY($0)
                    }
                #endif

                // .defersSystemGestures(on: .vertical)
            }
        }
    }
}

