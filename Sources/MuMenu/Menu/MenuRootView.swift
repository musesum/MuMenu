//  created by musesum on 6/11/22.

import SwiftUI

/// SwiftUI DragGesture to navigate menu

public struct MenuRootView: View {

    @GestureState private var touchXY: CGPoint = .zero
    let menuVm: MenuVm
    var cornerVm: CornerVm { menuVm.rootVm.cornerVm }

    public init(menuVm: MenuVm) {
        self.menuVm = menuVm
    }

    func geoFrame(_ geo: GeometryProxy) {
        cornerVm.updateBounds(geo.frame(in: .global))
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                StatusView()
                    .frame(width: geo.size.width, height: 18, alignment: .top)
                RootView()
                    .environmentObject(menuVm.rootVm)
                    .onAppear { geoFrame(geo) }
                    .onChange(of: geo.frame(in: .global)) { geoFrame(geo) }
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .updating($touchXY) { (value, touchXY, _) in touchXY = value.location })
                    .onChange(of: touchXY) { cornerVm.updateDragXY($1) }
                // .defersSystemGestures(on: .vertical)
            }
            //.environment(\.mainContent, AnyView(self))
        }

    }

}

