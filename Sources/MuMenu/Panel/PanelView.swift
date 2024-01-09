//  created by musesum on 5/23/22.

import SwiftUI

struct PanelView: View {

    @GestureState private var touchXY: CGPoint = .zero

    var leafVm: LeafVm
    var panelVm: PanelVm { leafVm.panelVm }
    var strokeColor: Color   { Layout.strokeColor(leafVm.spotlight) }
    var strokeWidth: CGFloat { Layout.strokeWidth(leafVm.spotlight) }
    
    var body: some View {
        ZStack {
            // fill
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Layout.panelFill)
                .overlay(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(strokeColor, lineWidth: strokeWidth))
                .frame(width:  panelVm.inner.width,
                       height: panelVm.inner.height)
        }
    }
}
