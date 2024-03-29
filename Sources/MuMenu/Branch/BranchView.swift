// created by musesum on 9/30/21.

import SwiftUI
import MuExtensions

struct BranchView: View {
    @EnvironmentObject var rootVm: RootVm
    @ObservedObject var branchVm: BranchVm
    var treeVm: TreeVm { branchVm.treeVm }

    init(branchVm: BranchVm) {
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
    @ObservedObject var branchVm: BranchVm
    var treeVm: TreeVm { branchVm.treeVm }
    var panelVm: PanelVm { branchVm.panelVm }
    var nodeSpotVm: NodeVm? { branchVm.nodeSpotVm }
    var offset: CGSize { branchVm.branchShift + branchVm.titleShift }
    var title: String {
        (nodeSpotVm as? LeafVm)?.leafProto?.treeTitle() ??
        nodeSpotVm?.node.title ?? "" }
    var size: CGSize { return (branchVm.nodeSpotVm?.nodeType ?? .none) == .xy 
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
        branchVm.show ? branchVm.opacity : 0 }

    init(_ branchVm: BranchVm) {
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
            .animation(Layout.animateSlow, value: opacity)
    }
}


/// Panel and closure(Content) for thumb of control
///
/// called by `MuLeaf*View` with only the control inside the panel
/// passed through as a closure
///
fileprivate struct bodyV: View {

    @ObservedObject var branchVm: BranchVm
    var treeVm: TreeVm { branchVm.treeVm }
    var rootVm: RootVm { branchVm.treeVm.rootVm }
    var panelVm: PanelVm { branchVm.panelVm }
    var spotlight: Bool { branchVm == treeVm.branchSpotVm }
    var opacity: CGFloat {
        branchVm.treeVm.depthShown == 0 ? 0 :
        branchVm.show ? branchVm.opacity : 0 }

    init(_ branchVm: BranchVm) {
        self.branchVm = branchVm
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BranchPanelView(spotlight: spotlight)
                VStack {
                    BranchAxisView(panelVm) {

                        ForEach(branchVm.treeVm.reverse
                                ? branchVm.nodeVms.reversed()
                                : branchVm.nodeVms) {
                            NodeView(nodeVm: $0)
                        }
                    }
                }
            }
            .onAppear { branchVm.updateBounds(geo.frame(in: .global)) }
            #if os(visionOS)
            .onChange(of: geo.frame(in: .global)) { old, now in branchVm.updateBounds(now) }
            #else
            .onChange(of: geo.frame(in: .global)) { branchVm.updateBounds($0) }
            #endif
        }
        .frame(width: panelVm.outer.width, height: panelVm.outer.height)
        .offset(branchVm.branchShift)
        .opacity(opacity)
        .animation(Layout.animateFast, value: opacity)
        .animation(Layout.animateFast, value: branchVm.branchShift )
        //.onTapGesture { } // allow scrolling
    }
}

struct BranchAxisView<Content: View>: View {

    let panelVm: PanelVm
    let content: () -> Content
    var spacing: CGFloat { panelVm.spacing }

    init(_ panel: PanelVm, @ViewBuilder content: @escaping () -> Content) {
        self.panelVm = panel
        self.content = content
    }

    var body: some View {

        // even though .vxy has only one inner view, a
        // .horizonal ScrollView shifts and truncates the inner views
        // so, perhaps there is a phantom space for indicators?

        if (panelVm.isVertical  ||
            panelVm.nodeType == .xy ||
            panelVm.nodeType == .peer) {

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading,
                       spacing: spacing,
                       content: content)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom,
                       spacing: spacing,
                       content: content)
            }
        }
    }
}
