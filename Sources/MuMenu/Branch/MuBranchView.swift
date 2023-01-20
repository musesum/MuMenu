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
            case .LLV, .LRV: VStack { titleV(branchVm); bodyV(branchVm)  }
            case .ULV, .URV: VStack { bodyV(branchVm) ; titleV(branchVm) }
            case .LLH, .ULH: HStack(alignment: .bottom) { bodyV(branchVm); titleV(branchVm) }
            case .URH, .LRH: HStack(alignment: .top) { titleV(branchVm); bodyV(branchVm)  }
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
    var offset: CGSize { branchVm.branchShift + branchVm.titleShift }
    var title: String {
        (nodeSpotVm as? MuLeafVm)?.leafProto?.treeTitle() ??
        nodeSpotVm?.node.title ?? "" }
    var size: CGSize { return (branchVm.nodeSpotVm?.nodeType ?? .none) == .vxy 
        ? CGSize(width: branchVm.boundsNow.width, height: Layout.radius)
        : CGSize(width: Layout.diameter, height: Layout.radius) }

    var angle: Angle {

        switch treeVm.cornerAxis.cornax {
            case .LLV, .LRV, .ULV, .URV: return  Angle(degrees:0)
            case .URH, .ULH: return  Angle(degrees:270) //TODO: 90 later, tricky
            case .LLH, .LRH: return  Angle(degrees:270)
        }
    }

    var anchor: UnitPoint {
        switch treeVm.cornerAxis.cornax {
            case .LLV, .LRV, .ULV, .URV: return .center
            case .LLH, .ULH: return .bottomLeading
            case .URH, .LRH: return .topTrailing
        }
    }

    var frameAlign: Alignment {
        switch treeVm.cornerAxis.cornax {
            case .LLV, .LRV, .ULV, .URV: return .center
            case .LLH: return .bottomLeading
            case .ULH: return .bottomLeading
            case .URH: return .topTrailing
            case .LRH: return .topTrailing
        }
    }


    var opacity: CGFloat {
        branchVm.treeVm.depthShown <= 1 ? 0 :
        //nodeSpotVm?.nodeType.isLeaf ?? true ? 0 :
        //treeVm.rootVm.touchState?.phase.isDone() ?? true ? 0 :
        branchVm.show ? branchVm.opacity : 0 }

    init(_ branchVm: MuBranchVm) {
        self.branchVm = branchVm
    }
    var body: some View {
        Text(title)
            .scaledToFit()
            .allowsTightening(true)
            .font(Font.system(size: 12, design: .default).leading(.tight))
            .minimumScaleFactor(0.01)
            .foregroundColor(Color.white)
            .shadow(color: .black, radius: 1.0)
            .frame(width: size.width, height: size.height, alignment: .center)
            .rotationEffect(angle, anchor: anchor)
            .offset(offset)
            .opacity(opacity)
            .animation(.easeInOut(duration: Layout.animate*2), value: opacity)
            //??? .animation(.easeInOut(duration: 0), value: offset)

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

