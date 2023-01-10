// Created by warren on 9/30/21.

import SwiftUI

struct MuBranchView: View {
    @EnvironmentObject var rootVm: MuRootVm
    @ObservedObject var branchVm: MuBranchVm
    let spotlight: Bool

    init( branchVm: MuBranchVm,
          spotlight: Bool) {

        self.branchVm = branchVm
        self.spotlight = spotlight
    }
    var body: some View {
        if branchVm.treeVm.isVertical {
            if rootVm.corner.contains(.lower) {
                VStack {
                    MuBranchTitleView(branchVm)
                    MuBranchBodyView(branchVm, spotlight)
                }
            } else {
                VStack {
                    MuBranchBodyView(branchVm, spotlight)
                    MuBranchTitleView(branchVm)
                }
            }
        } else if rootVm.corner.contains(.left) {
            HStack{
                MuBranchBodyView(branchVm, spotlight)
                MuBranchTitleView(branchVm)
            }
        } else {
            HStack{
                MuBranchTitleView(branchVm)
                MuBranchBodyView(branchVm, spotlight)
            }
        }
    }
}

/// title showing position of control
struct MuBranchTitleView: View {
    @EnvironmentObject var rootVm: MuRootVm
    @ObservedObject var branchVm: MuBranchVm
    var panelVm: MuPanelVm { branchVm.panelVm }
    var nodeSpotVm: MuNodeVm? { branchVm.nodeSpotVm }
    var branchTitle: String {nodeSpotVm?.node.title  ?? "??" }
    var opacity: CGFloat {
        nodeSpotVm?.nodeType.isLeaf ?? true ? 0 :
        rootVm.touchState?.phase.isDone() ?? true ? 0 :
        branchVm.show ? branchVm.branchOpacity : 0 }

    init(_ branchVm: MuBranchVm) {
        self.branchVm = branchVm
    }
    var body: some View {
        Text(branchTitle)
            .scaledToFit()
            .minimumScaleFactor(0.01)
            .foregroundColor(Color.white)
            .shadow(color: .black, radius: 1.0)
            .frame(width:  panelVm.titleSize.width,
                   height: panelVm.titleSize.height)
            .offset(branchVm.branchShift)
            .opacity(opacity)
            .animation(.easeInOut(duration: Layout.animate), value: opacity)
            .animation(.easeInOut(duration: branchVm.branchAnimate), value: branchVm.branchShift )
    }
}


/// Panel and closure(Content) for thumb of control
///
/// called by `MuLeaf*View` with only the control inside the panel
/// passed through as a closure
///
struct MuBranchBodyView: View {

    @ObservedObject var branchVm: MuBranchVm
    var rootVm: MuRootVm { branchVm.treeVm.rootVm }
    var panelVm: MuPanelVm { branchVm.panelVm }
    let spotlight: Bool
    var opacity: CGFloat { branchVm.show ? branchVm.branchOpacity : 0 }

    init(_ branchVm: MuBranchVm,
         _ spotlight: Bool) {

        self.branchVm = branchVm
        self.spotlight = spotlight
    }

    var body: some View {
        GeometryReader { geo in

            ZStack {
                MuBranchPanelView(panelVm: panelVm,
                                  spotlight: spotlight)

                let reverse = (panelVm.isVertical
                               ? rootVm.corner.contains(.lower) ? true : false
                               : rootVm.corner.contains(.right) ? true : false )
                VStack {

                    MuPanelAxisView(panelVm) {
                        ForEach(reverse
                                ? branchVm.nodeVms.reversed()
                                : branchVm.nodeVms) {
                            MuNodeView(nodeVm: $0)
                        }
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

