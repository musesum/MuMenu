// created by musesum on 3/27/24

import SwiftUI

/// translucent default for every panel; near-opaque pair is the graph panel's alone
enum PanelSkin {
    static let material = Material.ultraThinMaterial
    static let tint = Color.clear
    static let graphMaterial = Material.thickMaterial
    static let graphTint = Color(white: 0.08).opacity(0.94)
}

struct LeafBezelView<Content: View>: View {

    let leafVm: LeafVm
    let runwayType: LeafRunwayType
    /// panel edge, for a panel carrying its own; nil takes the menu's
    let rimColor: Color?
    let content: (() -> Content)?

    var size: CGSize { leafVm.panelVm.innerPanel(runwayType) }
    var strokeColor: Color   { rimColor ?? Menu.strokeColor(leafVm.spotlight) }
    var strokeWidth: CGFloat { Menu.strokeWidth(leafVm.spotlight) }

    init(_ leafVm: LeafVm,
         _ runwayType: LeafRunwayType,
         _ rimColor: Color? = nil,
         _ content: (() -> Content)? = nil) {

        self.leafVm = leafVm
        self.runwayType = runwayType
        self.rimColor = rimColor
        self.content = content
    }
    /// graph panel is the one near-opaque surface; the rest keep glass
    var isGraph: Bool { leafVm.nodeType == .graph }

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: Menu.cornerRadius)
                .fill(isGraph ? AnyShapeStyle(PanelSkin.graphMaterial)
                              : AnyShapeStyle(Material.ultraThinMaterial))
                .opacity(isGraph ? 1.0 : 0.62)
                .overlay(RoundedRectangle(cornerRadius: Menu.cornerRadius)
                    .fill(isGraph ? PanelSkin.graphTint : Color.clear))
                .overlay(RoundedRectangle(cornerRadius: Menu.cornerRadius)
                    .stroke(strokeColor, lineWidth: strokeWidth))
                .frame(width: size.width, height: size.height)
            content?()
                .onAppear {
                    let now = geo.frame(in: .global)
                    leafVm.runways.updateBounds(runwayType, now) }
                .onChange(of: geo.frame(in: .global)) {
                    leafVm.runways.updateBounds(runwayType, $1) }
        }
        .frame(width: size.width, height: size.height)
    }
}
