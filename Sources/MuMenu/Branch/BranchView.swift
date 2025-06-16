// created by musesum on 9/30/21.

import SwiftUI
import MuFlo

struct BranchView: View {

    @EnvironmentObject var rootVm: RootVm
    @ObservedObject var branchVm: BranchVm
    var treeVm: TreeVm { branchVm.treeVm }

    init(branchVm: BranchVm) {
        self.branchVm = branchVm
    }
    var body: some View {
        let cornerAxis = treeVm.menuType.cornerAxis
        if branchVm.columns > 1 {
            switch cornerAxis {
            case .DLV, .DRV: VStack                     { titleV(branchVm); gridV(branchVm)  }
            case .ULV, .URV: VStack                     { gridV(branchVm) ; titleV(branchVm) }
            case .DLH, .ULH: HStack(alignment: .bottom) { gridV(branchVm) ; titleV(branchVm) }
            case .URH, .DRH: HStack(alignment: .top)    { titleV(branchVm); gridV(branchVm)  }
            case .none     : VStack                     { titleV(branchVm); gridV(branchVm)  }
            }
        } else {
            switch cornerAxis {
            case .DLV, .DRV: VStack                     { titleV(branchVm); bodyV(branchVm)  }
            case .ULV, .URV: VStack                     { bodyV(branchVm) ; titleV(branchVm) }
            case .DLH, .ULH: HStack(alignment: .bottom) { bodyV(branchVm) ; titleV(branchVm) }
            case .URH, .DRH: HStack(alignment: .top)    { titleV(branchVm); bodyV(branchVm)  }
            case .none     : VStack                     { titleV(branchVm); bodyV(branchVm)  }
            }
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
    var title: String { nodeSpotVm?.treeTitle() ?? "" }

    var size: CGSize { CGSize(width: branchVm.boundsNow.width,
                              height: Layout.radius)
    }
    var angle: Angle {
        switch treeVm.menuType.cornerAxis {
        case .DLV, .DRV, .ULV, .URV, .none: return  Angle(degrees:0)
        case .URH, .ULH: return  Angle(degrees:270) //TODO: 90 later, tricky
        case .DLH, .DRH: return  Angle(degrees:270)
        }
    }

    var anchor: UnitPoint {
        switch treeVm.menuType.cornerAxis {
        case .DLV, .DRV, .ULV, .URV, .none: return .center
        case .DLH, .ULH: return .bottomLeading
        case .URH, .DRH: return .topTrailing
        }
    }

    var frameAlign: Alignment {
        switch treeVm.menuType.cornerAxis {
        case .DLV, .DRV, .ULV, .URV, .none: return .center
        case .DLH: return .bottomLeading
        case .ULH: return .bottomLeading
        case .URH: return .topTrailing
        case .DRH: return .topTrailing
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
            .animation(Animate(0.50), value: opacity)
    }
}

fileprivate struct gridV: View {

    @ObservedObject var branchVm: BranchVm

    var gridColumns:  [GridItem] { Array(repeating: GridItem(.flexible()), count: branchVm.columns) }
    var treeVm: TreeVm { branchVm.treeVm }
    var rootVm: RootVm { branchVm.treeVm.rootVm }
    var panelVm: PanelVm { branchVm.panelVm }
    var spotlight: Bool { branchVm == treeVm.branchSpotVm }
    var opacity: CGFloat {
        branchVm.treeVm.depthShown == 0 ? 0 :
        branchVm.show ? branchVm.opacity : 0 }

    var outerWidth: CGFloat { branchVm.panelVm.outerPanel.width }
    var outerHeight: CGFloat { branchVm.panelVm.outerPanel.height }
    var spacing: CGFloat { panelVm.spacing }

    init(_ branchVm: BranchVm) {
        self.branchVm = branchVm
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BranchPanelView(spotlight: spotlight)
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(branchVm.nodeVms) {
                        NodeView(nodeVm: $0)
                    }
                }
            }
            .onAppear { branchVm.updateBounds(geo.frame(in: .global)) }
            .onChange(of: geo.frame(in: .global)) { branchVm.updateBounds($1) }
        }
        .frame(width: outerWidth, height: outerHeight)
        .offset(branchVm.branchShift)
        .opacity(opacity)
        .animation(Animate(0.25), value: opacity)
        .animation(Animate(0.50), value: branchVm.branchShift )
    }
}


/// Panel and closure(Content) for thumb of control
fileprivate struct bodyV: View {

    @ObservedObject var branchVm: BranchVm

    var treeVm: TreeVm { branchVm.treeVm }
    var rootVm: RootVm { branchVm.treeVm.rootVm }
    var panelVm: PanelVm { branchVm.panelVm }
    var outerPanel: CGSize { panelVm.outerPanel }
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
                        ForEach(branchVm.nodeVms) {
                            if $0.nodeType == .tog {
                                NodeView(nodeVm: $0)
                            } else {
                                NodeView(nodeVm: $0)
                            }
                        }
                    }
                }
            }
            .onAppear { branchVm.updateBounds(geo.frame(in: .global)) }
            .onChange(of: geo.frame(in: .global)) { branchVm.updateBounds($1) }
        }
        .frame(width: outerPanel.width,
               height: outerPanel.height)

        .offset(branchVm.branchShift)
        .opacity(opacity)
        .animation(Animate(0.50), value: opacity)
        .animation(Animate(0.25), value: branchVm.branchShift )
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
        // .horizonal scroll view shifts and truncates the inner views
        // so, perhaps there is a phantom space for indicators?
        
        if panelVm.menuType.vertical ||
            [.xy, .xyz, .arch, .peer].contains(panelVm.nodeType) {

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: spacing, content: content)
            }
            .scrollDisabled(true)
        }
        else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: spacing, content: content)
            }
            .scrollDisabled(true)
        }
    }
}
