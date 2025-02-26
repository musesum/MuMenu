// created by musesum on 12/22/23

import SwiftUI

struct CursorView: View {

    @ObservedObject var nodeVm: NodeVm
    var diameter: CGFloat
    var panelVm: PanelVm { nodeVm.panelVm }

    init(_ nodeVm: NodeVm,
         _ diameter: CGFloat) {
        
        self.nodeVm = nodeVm
        self.diameter = diameter
    }

    var body: some View {
        GeometryReader() { geo in
            IconView(nodeVm, nodeVm.menuTree.icon, .none)
                .onChange(of: geo.frame(in: .global)) { nodeVm.updateCenter($1) }
                .onAppear { nodeVm.updateCenter(geo.frame(in: .global)) }
                .cornerRadius(Layout.cornerRadius)
        }
        .frame(width: diameter, height: diameter)
        .padding(Layout.padding)
        .zIndex(nodeVm.zIndex)
    }
}
