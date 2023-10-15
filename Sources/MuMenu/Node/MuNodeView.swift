// created by musesum on 10/1/21.

import SwiftUI


struct MuNodeView: View {

    @ObservedObject var nodeVm: MuNodeVm
    var panelVm: MuPanelVm { nodeVm.panelVm }

    var body: some View {
        GeometryReader() { geo in
            Group {
                switch nodeVm {
                case let n as MuLeafVxyVm: MuLeafVxyView(leafVm: n)
                case let n as MuLeafValVm: MuLeafValView(leafVm: n)
                case let n as MuLeafSegVm: MuLeafSegView(leafVm: n)
                case let n as MuLeafPeerVm: MuLeafPeerView(leafVm: n)
                case let n as MuLeafTogVm: MuLeafTogView(leafVm: n)
                case let n as MuLeafTapVm: MuLeafTapView(leafVm: n)
                default: MuIconView(nodeVm: nodeVm, icon: nodeVm.node.icon)
                }
            }
            #if os(xrOS)
            .onChange(of: geo.frame(in: .global)) { old,now in nodeVm.updateCenter(now) }
            #else
            .onChange(of: geo.frame(in: .global)) { nodeVm.updateCenter($0) }
            #endif
            .onAppear { nodeVm.updateCenter(geo.frame(in: .global)) }
        }
        .frame(width: panelVm.inner.width, height: panelVm.inner.height)
        .padding(Layout.padding)
        .zIndex(nodeVm.zIndex)
    }
}


struct MuCursorView: View {

    @ObservedObject var nodeVm: MuNodeVm
    var diameter: CGFloat
    var panelVm: MuPanelVm { nodeVm.panelVm }

    init(_ nodeVm: MuNodeVm,
         _ diameter: CGFloat) {
        self.nodeVm = nodeVm
        self.diameter = diameter
    }

    var body: some View {
        GeometryReader() { geo in
            MuIconView(nodeVm: nodeVm, icon: nodeVm.node.icon)
            #if os(xrOS)
            .onChange(of: geo.frame(in: .global)) { old, now in nodeVm.updateCenter(now) }
            #else
            .onChange(of: geo.frame(in: .global)) { nodeVm.updateCenter($0) }
            #endif
            .onAppear { nodeVm.updateCenter(geo.frame(in: .global)) }
        }
        .frame(width: diameter, height: diameter)
        .padding(Layout.padding)
        .zIndex(nodeVm.zIndex)
    }
}


