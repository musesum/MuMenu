// Created by warren on 9/30/21.

import SwiftUI

struct MuBranchView: View {
    @EnvironmentObject var rootVm: MuRootVm
    @ObservedObject var branchVm: MuBranchVm
    var treeVm: MuTreeVm { branchVm.treeVm }
    init(branchVm: MuBranchVm) {
        self.branchVm = branchVm
    }
    var body: some View {
        switch treeVm.cornerAxis.cornax {
            case .LLV, .LRV: VStack { titleV(branchVm, .center); bodyV(branchVm)  }
            case .ULV, .URV: VStack { bodyV(branchVm) ; titleV(branchVm, .center) }
            case .LLH, .ULH: HStack { bodyV(branchVm) ; titleV(branchVm, .leading) }
            case .URH, .LRH: HStack { titleV(branchVm, .trailing); bodyV(branchVm) }
        }
    }
}

/// title showing position of control
fileprivate struct titleV: View {
    
    //@EnvironmentObject var rootVm: MuRootVm
    @ObservedObject var branchVm: MuBranchVm
    var treeVm: MuTreeVm { branchVm.treeVm }
    var panelVm: MuPanelVm { branchVm.panelVm }
    var nodeSpotVm: MuNodeVm? { branchVm.nodeSpotVm }
    var branchTitle: String { nodeSpotVm?.node.title  ?? "??" }
    var offset: CGSize { branchVm.branchShift + branchVm.titleShift }
    var align: Alignment
    
    var opacity: CGFloat {
        branchVm.treeVm.depthShown == 0 ? 0 :
        nodeSpotVm?.nodeType.isLeaf ?? true ? 0 :
        treeVm.rootVm.touchState?.phase.isDone() ?? true ? 0 :
        branchVm.show ? branchVm.opacity : 0 }

    init(_ branchVm: MuBranchVm,
         _ align: Alignment) {
        self.branchVm = branchVm
        self.align = align
    }
    var body: some View {
        Text(branchTitle)
            .scaledToFit()
            .allowsTightening(true)
            .font(Font.system(size: 14, design: .default))
            .minimumScaleFactor(0.01)
            .foregroundColor(Color.white)
            .shadow(color: .black, radius: 1.0)
            .frame(width:  Layout.labelSize.width,
                   height: Layout.labelSize.height,
                   alignment: align)
            .offset(offset)
            .opacity(opacity)
            .animation(.easeInOut(duration: Layout.animate), value: opacity)
            .animation(.easeInOut(duration: Layout.animate), value: offset)
    }
}


/// Panel and closure(Content) for thumb of control
///
/// called by `MuLeaf*View` with only the control inside the panel
/// passed through as a closure
///
fileprivate struct bodyV: View {

    @ObservedObject var branchVm: MuBranchVm
    var treeVm: MuTreeVm { branchVm.treeVm }
    var rootVm: MuRootVm { branchVm.treeVm.rootVm }
    var panelVm: MuPanelVm { branchVm.panelVm }
    var spotlight: Bool { branchVm == treeVm.branchSpotVm }
    var opacity: CGFloat {
        branchVm.treeVm.depthShown == 0 ? 0 :
        branchVm.show ? branchVm.opacity : 0 }

    init(_ branchVm: MuBranchVm) {
        self.branchVm = branchVm

    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MuBranchPanelView(spotlight: spotlight)
                VStack {
                    MuPanelAxisView(panelVm) {

                        ForEach(branchVm.treeVm.reversed()
                                ? branchVm.nodeVms.reversed()
                                : branchVm.nodeVms) {
                            MuNodeView(nodeVm: $0)
                        }
                    }
                }
            }
            .onAppear { branchVm.updateBounds(geo.frame(in: .global)) }
            .onChange(of: geo.frame(in: .global)) { branchVm.updateBounds($0) }
        }
        .frame(width: panelVm.outer.width, height: panelVm.outer.height)
        .offset(branchVm.branchShift)
        .opacity(opacity)
        .animation(.easeInOut(duration: Layout.animate), value: opacity)
        .animation(.easeInOut(duration: Layout.animate), value: branchVm.branchShift )
        //.onTapGesture { } // allow scrolling
    }
}

