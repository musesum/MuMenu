// Created by warren on 9/30/21.

import SwiftUI

struct MuBranchView: View {

    @EnvironmentObject var rootVm: MuRootVm
    @ObservedObject var branchVm: MuBranchVm

    var panelVm: MuPanelVm { branchVm.panelVm }
    var spotlight: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MuBranchPanelView(panelVm: panelVm,
                                  spotlight: spotlight)

                let reverse = (panelVm.axis == .vertical
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
            .onAppear { branchVm.updateBranchBounds(geo.frame(in: .global)) }
            .onChange(of: geo.frame(in: .global)) { branchVm.updateBranchBounds($0) }
        }
        .frame(width: panelVm.outer.width, height: panelVm.outer.height)
        .offset(branchVm.branchShift)
        .opacity(branchVm.viewOpacity)
        .animation(.easeInOut(duration: branchVm.duration), value: branchVm.viewOpacity)
        .animation(.easeInOut(duration: branchVm.duration), value: branchVm.branchShift )
        //.onTapGesture { } // allow scrolling
    }
}
