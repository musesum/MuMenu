// created by musesum on 10/1/21.

import SwiftUI

struct NodeView: View {

    @ObservedObject var nodeVm: NodeVm
    var size: CGSize {
        #if os(watchOS)
        // All node types collapse to a single icon slot on watchOS so the
        // menu column has uniform circle sizes. Leaves that need richer
        // interaction (XY/XYZ/val/seg) get the WatchLeafController overlay.
        switch nodeVm.menuTree.nodeType {
        case .none, .node, .tog, .tap:
            return nodeVm.panelVm.innerPanel(.none)
        default:
            return CGSize(width: Menu.diameter, height: Menu.diameter)
        }
        #else
        return nodeVm.panelVm.innerPanel(.none)
        #endif
    }

    var body: some View {
        GeometryReader() { geo in
            Group {
                switch nodeVm {
                #if !os(watchOS)
                // Inline panel-XY / panel-XYZ / panel-Seg / panel-Val leaves
                // render inside their iOS/visionOS panel slot. On watchOS they
                // collapse to plain IconView in the menu space; full-face
                // WatchLeafController takes over for interaction.
                case let n as LeafXyVm      : LeafXyView      (leafVm: n)
                case let n as LeafXyzVm     : LeafXyzView     (leafVm: n)
                case let n as LeafSegVm     : LeafSegView     (leafVm: n)
                case let n as LeafValVm     : LeafValView     (leafVm: n)
                #endif
                #if !os(watchOS)
                case let n as LeafPeerVm    : LeafPeerView    (leafVm: n)
                case let n as LeafSearchVm  : LeafSearchView  (leafVm: n)
                case let n as LeafArchiveVm : LeafArchiveView (leafVm: n)
                #endif
                case let n as LeafTogVm     : LeafTogView     (leafVm: n)
                case let n as LeafTapVm     : LeafTapView     (leafVm: n)
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
