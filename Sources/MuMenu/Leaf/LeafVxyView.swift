//  created by musesum on 5/10/22.

import SwiftUI

struct LeafVxyView: View {
    
    @ObservedObject var leafVm: LeafVxyVm
    var panelVm: PanelVm { leafVm.panelVm }
    
    var body: some View {
        VStack {
            if panelVm.cornerAxis.corner.upper {
                LeafBodyView(leafVm) {
                    ZStack {
                        // tick marks
                        ForEach(leafVm.ticks, id: \.self) {
                            Capsule()
                                .fill(.gray)
                                .frame(width: 4, height: 4)
                                .offset(CGSize(width: $0.width,
                                               height: $0.height))
                                .allowsHitTesting(false)
                        }
                        LeafThumbSlideView(leafVm: leafVm)
                    }
                }
                LeafTitleView(leafVm)
            } else {
                LeafTitleView(leafVm)
                LeafBodyView(leafVm) {
                    ZStack {
                        // tick marks
                        ForEach(leafVm.ticks, id: \.self) {
                            Capsule()
                                .fill(.gray)
                                .frame(width: 4, height: 4)
                                .offset(CGSize(width: $0.width,
                                               height: $0.height))
                                .allowsHitTesting(false)
                        }
                        LeafThumbSlideView(leafVm: leafVm)
                    }
                }
            }
        }
    }
}
