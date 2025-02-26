//  created by musesum on 6/21/22.

import SwiftUI
/// Generic layout of title and control based on axis
struct LeafView<Content: View>: View {

    let leafVm: LeafVm
    let content: () -> Content
    var panelVm: PanelVm { leafVm.panelVm }
    var size: CGSize { panelVm.innerPanel(.runXY) }

    init(_ leafVm: LeafVm, @ViewBuilder content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }

    var body: some View {

        if leafVm.nodeType.isTogTap {

            LeafTogBodyView(leafVm, content)
            
        } else if panelVm.isVertical {
            VStack {
                // vertical title is always on top
                // so that hand doesn't occlude value text
                LeafHeaderView(leafVm)
                LeafBezelView(leafVm, .runXY, content)
            }
        } else {
            HStack {
                // horizontal title is farthest away from root
                // to allow control to be a bit more reachable
                if panelVm.corner.cornerOp.left {
                    LeafBezelView(leafVm, .runXY, content)
                    LeafHeaderView(leafVm)
                } else {
                    LeafHeaderView(leafVm)
                    LeafBezelView(leafVm, .runXY, content)
                }
            }
        }
    }
}

