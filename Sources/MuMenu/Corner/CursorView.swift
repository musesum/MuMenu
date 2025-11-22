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
                .cornerRadius(Menu.cornerRadius)
        }
        .frame(width: diameter, height: diameter)
        .padding(Menu.padding)
        .zIndex(nodeVm.zIndex)
    }
}
struct NodeIconView: View {

    @Environment(\.colorScheme) var colorScheme // darkMode
    @ObservedObject var nodeVm: NodeVm

    let icon: Icon
    var title: String { nodeVm.menuTree.flo.name }
    var spotlight: Bool { nodeVm.spotlight }
    var fillColor = Color(white: 0).opacity(0.62)
    var strokeColor: Color { spotlight ? .white : Color(white: 0.7) }
    var strokeWidth: CGFloat { spotlight ? 5.0 : 1.0 }

    init(_ nodeVm: NodeVm,
         _ icon: Icon) {
        self.nodeVm = nodeVm
        self.icon = icon
    }

    var body: some View {
        ZStack {

            if icon.typeOn != .cursor {

                RoundedRectangle(cornerRadius: Menu.cornerRadius)
                    .fill(fillColor)
                    .overlay(RoundedRectangle(cornerRadius:  Menu.cornerRadius)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        .background(.clear)
                    )

                    .hoverEffect()
                    .cornerRadius(Menu.cornerRadius)

            }
            IconTitleView(title: title, color: strokeColor)

        }
        .allowsHitTesting(true)
    }
}
