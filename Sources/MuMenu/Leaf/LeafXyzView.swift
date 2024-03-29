//  created by musesum on 5/10/22.

import SwiftUI
import MuExtensions

struct LeafXyzView: View {

    @ObservedObject var leafVm: LeafXyzVm

    var body: some View {
        VStack(spacing: 12) {
            if leafVm.panelVm.cornerAxis.corner.upper {
                LeafBodyXyzView(leafVm)
                LeafTitleView(leafVm)
            } else {
                LeafTitleView(leafVm)
                LeafBodyXyzView(leafVm)
            }
        }
    }
}
public struct LeafBodyXyzView: View {

    @ObservedObject var leafVm: LeafXyzVm
    var panelVm: PanelVm { leafVm.panelVm }
    var size: CGSize { panelVm.inner(.xyz)}

    public init(_ leafVm: LeafXyzVm) {
        self.leafVm = leafVm
    }
    public var body: some View {
        
        VStack(alignment: .center, spacing: 3) {
            HStack(alignment: .center, spacing: 3) {

                LeafBezelView(leafVm, .y) {
                    LeafThumbSlideView(leafVm, .y)
                }
                LeafBezelView(leafVm, .xyz)  {
                    ZStack {
                        LeafTicksView(leafVm.ticks())
                        LeafThumbSlideView(leafVm, .xyz)
                    }
                }
                LeafBezelView(leafVm, .z) {
                    LeafThumbSlideView(leafVm, .z)
                }
            }
            LeafBezelView(leafVm, .x) {
                LeafThumbSlideView(leafVm, .x)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}


