// Created by warren 10/29/21.

import SwiftUI

struct MuTouchView: View {

    @ObservedObject var touchVm: MuTouchVm
    let offset = CGSize(width: Layout.padding2, height: -Layout.padding2)
    var body: some View {

        GeometryReader() { geo  in
            // parked icon
            if let rootNodeVm = touchVm.rootNodeVm {
                
                MuCursorView(rootNodeVm, Layout.diameter)
                   
                    .onAppear { touchVm.updateRootIcon(geo.frame(in: .global)) }
                    .onChange(of: geo.frame(in: .global)) { touchVm.updateRootIcon($0) }
                    .padding(Layout.padding2)
                    .opacity(touchVm.parkIconAlpha + 0.1)
                    .position(touchVm.parkIconXY)
                    .offset(touchVm.rootVm?.rootOffset ?? .zero)
            }

            // drag icon, follows touch
            if let dragNodeVm = touchVm.dragNodeVm {

                MuCursorView(dragNodeVm, Layout.diameter2)
                    .position(touchVm.dragIconXY)
                    .animation(Layout.animateFast, value: touchVm.dragIconXY)
                    .opacity(1-touchVm.parkIconAlpha)
                    .offset(touchVm.dragNodeΔ)
            }
        }
        .animation(Layout.animateFast, value: touchVm.parkIconAlpha)
    }
}
