// Created by warren 10/29/21.

import SwiftUI

struct MuTouchView: View {

    @ObservedObject var touchVm: MuTouchVm

    var body: some View {

        GeometryReader() { geo  in
            // parked icon
            if let rootNodeVm = touchVm.rootNodeVm {
                
                MuNodeView(nodeVm: rootNodeVm)
                    .frame(width: Layout.diameter, height: Layout.diameter)
                    .onAppear { touchVm.updateRootIcon(geo.frame(in: .global)) }
                    .onChange(of: geo.frame(in: .global)) { touchVm.updateRootIcon($0) }
                    .padding(Layout.padding)
                    .opacity(touchVm.parkIconAlpha + 0.1)
                    .position(touchVm.parkIconXY)
            }

            // drag icon, follows touch
            if let dragNodeVm = touchVm.dragNodeVm {

                MuNodeView(nodeVm: dragNodeVm)
                    .position(touchVm.dragIconXY)
                    .animation(.easeInOut(duration: Layout.animate),
                               value: touchVm.dragIconXY)
                
                    .opacity(1-touchVm.parkIconAlpha)
                    .offset(touchVm.dragNodeΔ)
            }
        }
        .animation(.easeInOut(duration: Layout.animate), value: touchVm.parkIconAlpha)
    }
}
