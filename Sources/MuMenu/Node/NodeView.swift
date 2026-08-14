// created by musesum on 10/1/21.

import SwiftUI

struct NodeView: View {

    @ObservedObject var nodeVm: NodeVm
    var size: CGSize { nodeVm.panelVm.innerPanel(.none) }

    var body: some View {
        GeometryReader() { geo in
            Group {
                switch nodeVm {
                // Inline panel-XY / panel-XYZ / panel-Seg / panel-Val leaves
                // render in their natural panel slot on ALL platforms so the
                // menu-mode small leaf is a live representation (thumb moves
                // with value). watchOS edit-mode still routes through the
                // full-face WatchLeafController for richer interaction.
                case let n as LeafXyVm      : LeafXyView      (leafVm: n)
                case let n as LeafXyzwVm    : LeafXyzwView    (leafVm: n) // before LeafXyzVm: subclass must match first
                case let n as LeafVfVm      : LeafVfView      (leafVm: n)
                case let n as LeafXyzVm     : LeafXyzView     (leafVm: n)
                case let n as LeafSegVm     : LeafSegView     (leafVm: n)
                case let n as LeafValVm     : LeafValView     (leafVm: n)
                #if !os(watchOS)
                case let n as LeafPeerVm    : LeafPeerView    (leafVm: n)
                case let n as LeafSearchVm  : LeafSearchView  (leafVm: n)
                case let n as LeafArchiveVm : LeafArchiveView (leafVm: n)
                case let n as LeafGraphVm   : LeafGraphView   (leafVm: n)
                case let n as LeafCodeVm    : LeafCodeView    (leafVm: n)
                case let n as LeafMidiVm    : LeafMidiView    (leafVm: n)
                case let n as LeafSequencerVm : LeafSequencerView (leafVm: n)
                #endif
                case let n as LeafTogVm     : LeafTogView     (leafVm: n)
                case let n as LeafTapVm     : LeafTapView     (leafVm: n)
                default: IconView(nodeVm, nodeVm.menuTree.icon, .none)
                }
            }
            #if os(watchOS)
            // Menu-mode cover on watchOS: the leaf body is a live visual
            // representation only. All touch/drag/tap belongs to the outer
            // ContentView gesture chain (sticky-leaf detection + lift/double
            // tap → edit mode), and to the crown for MRU navigation. Letting
            // the inner runways absorb touches stole gestures from the MRU
            // stack — especially for XYZ which renders the largest panel.
            .allowsHitTesting(false)
            #endif
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
