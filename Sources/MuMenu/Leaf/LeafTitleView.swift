// created by musesum on 3/27/24

import SwiftUI

/// title showing position of control
struct LeafTitleView: View {

    @ObservedObject var leafVm: LeafVm
    var leafTitle: String { leafVm.leafProto?.leafTitle() ?? "??"}
    var size: CGSize { leafVm.panelVm.titleSize }

    init(_ leafVm: LeafVm) {
        self.leafVm = leafVm
    }
    var body: some View {
        Text(leafTitle)
            .scaledToFit()
            .allowsTightening(true)
            .font(Font.system(size: 14, design: .default))
            .minimumScaleFactor(0.01)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 1.0)
            .frame(width:  size.width,
                   height: size.height,
                   alignment: .center)
    }
}
