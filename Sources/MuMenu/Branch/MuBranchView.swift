// Created by warren on 9/30/21.

import SwiftUI

struct MuBranchView: View {

    @EnvironmentObject var rootVm: MuRootVm
    @ObservedObject var branchVm: MuBranchVm

    var panelVm: MuPanelVm { branchVm.panelVm }
    var spotlight: Bool
    var opacity: CGFloat  { branchVm.show ? branchVm.branchOpacity : 0 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MuBranchPanelView(panelVm: panelVm,
                                  spotlight: spotlight)

                let reverse = (panelVm.isVertical
                               ? rootVm.corner.contains(.lower) ? true : false
                               : rootVm.corner.contains(.right) ? true : false )

                MuPanelAxisView(panelVm) {
                    ForEach(reverse
                            ? branchVm.nodeVms.reversed()
                            : branchVm.nodeVms) {
                        MuNodeView(nodeVm: $0)
                    }
                }
            }
            .onAppear { branchVm.updateOnAppear( geo.frame(in: .global)) }
            .onChange(of: geo.frame(in: .global)) { branchVm.updateOnChange($0) }
        }
        .frame(width: panelVm.outer.width, height: panelVm.outer.height)
        .offset(branchVm.branchShift)
        .opacity(opacity)
        .animation(.easeInOut(duration: Layout.animate), value: opacity)
        .animation(.easeInOut(duration: branchVm.branchAnimate), value: branchVm.branchShift )
        //.onTapGesture { } // allow scrolling
    }
}
