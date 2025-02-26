// created by musesum on 3/27/24

import SwiftUI
import MuFlo

struct LeafBezelView<Content: View>: View {

    let leafVm: LeafVm
    let runway: Runway
    let content: (() -> Content)?
    
    var size: CGSize { leafVm.panelVm.innerPanel(runway) }
    var strokeColor: Color   { Layout.strokeColor(leafVm.spotlight) }
    var strokeWidth: CGFloat { Layout.strokeWidth(leafVm.spotlight) }

    init(_ leafVm: LeafVm,
         _ runway: Runway,
         _ content: (() -> Content)? = nil) {

        self.leafVm = leafVm
        self.runway = runway
        self.content = content
    }
    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Layout.panelFill)
                .overlay(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(strokeColor, lineWidth: strokeWidth))
                .frame(width: size.width, height: size.height)
            content?()
                .onAppear {
                    let now = geo.frame(in: .global)
                   
                    leafVm.updateRunway(runway, now) }
                .onChange(of: geo.frame(in: .global)) {
                    leafVm.updateRunway(runway, $1) }
        }
        .frame(width: size.width, height: size.height)

    }
}
