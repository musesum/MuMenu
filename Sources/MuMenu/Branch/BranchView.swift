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
            case .SWV, .SEV: VStack { Title(branchVm); Grid(branchVm)  }
            case .NWV, .NEV: VStack { Grid(branchVm) ; Title(branchVm) }
            case .SWH, .NWH: HStack { Grid(branchVm) ; Title(branchVm) }
            case .NEH, .SEH: HStack { Title(branchVm); Grid(branchVm)  }
            case .none     : VStack { Title(branchVm); Grid(branchVm)  }
            }
        } else {
            switch cornerAxis {
            case .SWV, .SEV: VStack { Title(branchVm); Body_(branchVm)  }
            case .NWV, .NEV: VStack { Body_(branchVm); Title(branchVm) }
            case .SWH, .NWH: HStack { Body_(branchVm); Title(branchVm) }
            case .NEH, .SEH: HStack { Title(branchVm); Body_(branchVm)  }
            case .none     : VStack { Title(branchVm); Body_(branchVm)  }
            }
        }
    }
}

/// title showing position of control
fileprivate struct Title: View {
    @ObservedObject var branchVm: BranchVm
    var treeVm     : TreeVm  { branchVm.treeVm }
    var panelVm    : PanelVm { branchVm.panelVm }
    var nodeSpotVm : NodeVm? { branchVm.nodeSpotVm }
    var title      : String  { nodeSpotVm?.treeTitle() ?? "" }

    var size: CGSize { CGSize(width: branchVm.boundsNow.width,
                              height: Menu.radius)
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
            .offset(branchVm.offset)
            .opacity(opacity)
            .animation(Animate(0.50), value: opacity)
    }
}

fileprivate struct Grid: View {

    @ObservedObject var branchVm: BranchVm

    var gridColumns:  [GridItem] { Array(repeating: GridItem(.flexible()), count: branchVm.columns) }
    var treeVm: TreeVm { branchVm.treeVm }
    var rootVm: RootVm { branchVm.treeVm.rootVm }
    var panelVm: PanelVm { branchVm.panelVm }
    var spotlight: Bool { branchVm == treeVm.branchSpotVm }
    var opacity: CGFloat {
        branchVm.treeVm.depthShown == 0 ? 0 :
        branchVm.show ? branchVm.opacity : 0 }
    var outerPanel: CGSize { branchVm.panelVm.outerPanel }
    var outerWidth: CGFloat { outerPanel.width }
    var outerHeight: CGFloat { outerPanel.height }
    var spacing: CGFloat { panelVm.spacing }

    init(_ branchVm: BranchVm) {
        self.branchVm = branchVm
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BranchPanelView()
                    .cornerRadius(Menu.cornerRadius)
                LazyVGrid(columns: gridColumns, spacing: 0) {
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
    }
}


/// Panel and closure(Content) for thumb of control
fileprivate struct Body_: View {

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
                BranchPanelView()
                    .cornerRadius(Menu.cornerRadius)
                VStack {
                    BranchAxisView(panelVm) {
                        ForEach(branchVm.nodeVms) {
                            NodeView(nodeVm: $0)
                        }
                    }
                }
            }
            .onAppear { branchVm.updateBounds(geo.frame(in: .global)) }
            .onChange(of: geo.frame(in: .global)) { branchVm.updateBounds($1) }
        }
        .frame(width: outerPanel.width, height: outerPanel.height)
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

        // even though .vxy has only one inner view, a .horizonal scroll view shifts and truncates the inner views. So, perhaps there is a phantom space for indicators?

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
