// created by musesum on 3/27/24

import SwiftUI

struct LeafBezelView<Content: View>: View {

    let leafVm: LeafVm
    let runwayType: RunwayType
    var size: CGSize { leafVm.panelVm.inner(runwayType) }

    let content: (() -> Content)?

    var strokeColor: Color   { Layout.strokeColor(leafVm.spotlight) }
    var strokeWidth: CGFloat { Layout.strokeWidth(leafVm.spotlight) }

    init(_ leafVm: LeafVm,
         _ runwayType: RunwayType,
         _ content: (() -> Content)? = nil) {

        self.leafVm = leafVm
        self.runwayType = runwayType
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
                    print("xyz appear \(leafVm.node.title)\(now.script)")
                    leafVm.updateRunway(runwayType, now) }
                #if os(visionOS)
                .onChange(of: geo.frame(in: .global)) { old, now in
                    leafVm.updateRunway(runwayType, now) }
                #else
                .onChange(of: geo.frame(in: .global)) {
                    print("xyz change \(leafVm.node.title)\($0.script)")
                    leafVm.updateRunway(runwayType,$0) }
                #endif
        }
        .frame(width: size.width, height: size.height)
    }
}
