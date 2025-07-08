// created by musesum on 3/27/24

import SwiftUI

struct LeafBezelView<Content: View>: View {

    let leafVm: LeafVm
    let runwayType: LeafRunwayType
    let content: (() -> Content)?
    
    var size: CGSize { leafVm.panelVm.innerPanel(runwayType) }
    var strokeColor: Color   { Menu.strokeColor(leafVm.spotlight) }
    var strokeWidth: CGFloat { Menu.strokeWidth(leafVm.spotlight) }

    init(_ leafVm: LeafVm,
         _ runwayType: LeafRunwayType,
         _ content: (() -> Content)? = nil) {

        self.leafVm = leafVm
        self.runwayType = runwayType
        self.content = content
    }
    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: Menu.cornerRadius)
                .fill(Menu.panelFill)
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
