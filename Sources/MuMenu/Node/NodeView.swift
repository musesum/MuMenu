// created by musesum on 10/1/21.

import SwiftUI

struct NodeView: View {

    @ObservedObject var nodeVm: NodeVm
    var size: CGSize { nodeVm.panelVm.innerPanel(.none) }

    var body: some View {
        GeometryReader() { geo in
            Group {
                switch nodeVm {
                case let n as LeafXyVm      : LeafXyView      (leafVm: n)
                case let n as LeafXyzVm     : LeafXyzView     (leafVm: n)
                case let n as LeafSegVm     : LeafSegView     (leafVm: n)
                case let n as LeafValVm     : LeafValView     (leafVm: n)
                case let n as LeafPeerVm    : LeafPeerView    (leafVm: n)
                case let n as LeafSearchVm  : LeafSearchView  (leafVm: n)
                case let n as LeafArchiveVm : LeafArchiveView (leafVm: n)
                case let n as LeafTogVm     : LeafTogView     (leafVm: n)
                default: IconView(nodeVm, nodeVm.menuTree.icon, .none)
                }
            }
            .onAppear { nodeVm.updateCenter(geo.frame(in: .global)) }
            .onChange(of: geo.frame(in: .global)) { nodeVm.updateCenter($1) }
        }
        .frame(width: size.width, height: size.height)
        .padding(Menu.padding)
        .zIndex(nodeVm.zIndex)
    }
}

extension NodeVm: @MainActor Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(nodeHash)
        _ = hasher.finalize()
        //print(path + String(format: ": %i", result))
    }
}
