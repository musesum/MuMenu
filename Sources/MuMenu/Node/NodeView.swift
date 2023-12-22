// created by musesum on 10/1/21.

import SwiftUI


struct NodeView: View {

    @ObservedObject var nodeVm: NodeVm
    var panelVm: PanelVm { nodeVm.panelVm }

    var body: some View {
        GeometryReader() { geo in
            Group {
                switch nodeVm {
                case let n as LeafVxyVm: LeafVxyView(leafVm: n)
                case let n as LeafValVm: LeafValView(leafVm: n)
                case let n as LeafSegVm: LeafSegView(leafVm: n)
                case let n as LeafPeerVm: LeafPeerView(leafVm: n)
                case let n as LeafTogVm: LeafTogView(leafVm: n)
                case let n as LeafTapVm: LeafTapView(leafVm: n)
                default: IconView(nodeVm: nodeVm, icon: nodeVm.node.icon)
                }
            }
            #if os(visionOS)
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



