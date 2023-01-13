// Created by warren on 10/1/21.

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
                    case let n as MuLeafTogVm: MuLeafTogView(leafVm: n)
                    case let n as MuLeafTapVm: MuLeafTapView(leafVm: n)
                    case let n as MuLeafPeerVm: MuLeafPeerView(leafVm: n)
                        
                    default: MuIconView(nodeVm: nodeVm, icon: nodeVm.node.icon)
                }
            }
            .onChange(of: geo.frame(in: .global)) { nodeVm.updateCenter($0) }
            .onAppear { nodeVm.updateCenter(geo.frame(in: .global)) }
        }
        .frame(width: panelVm.inner.width, height: panelVm.inner.height)
        .padding(Layout.padding)
    }
}


