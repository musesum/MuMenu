//  created by musesum on 6/21/22.

import SwiftUI
/// Generic layout of title and control based on axis
struct LeafView<Content: View>: View {

    let leafVm: LeafVm
    let content: () -> Content
    var panelVm: PanelVm { leafVm.panelVm }
    var size: CGSize { panelVm.inner(.xy) }

    init(_ leafVm: LeafVm, @ViewBuilder content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }

    var body: some View {

        if leafVm.nodeType.isTog {

            LeafTogBodyView(leafVm, content)
            
        } else if panelVm.isVertical {
            VStack {
                // vertical title is always on top
                // so that hand doesn't occlude value text
                LeafTitleView(leafVm)
                LeafBezelView(leafVm, .xy, content)
            }
        } else {
            HStack {
                // horizontal title is farthest away from root
                // to allow control to be a bit more reachable
                if panelVm.cornerItem.corner.left {
                    LeafBezelView(leafVm, .xy, content)
                    LeafTitleView(leafVm)
                } else {
                    LeafTitleView(leafVm)
                    LeafBezelView(leafVm, .xy, content)
                }
            }
        }
    }
}

