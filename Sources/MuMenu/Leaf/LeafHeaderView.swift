// created by musesum on 3/27/24

import SwiftUI
import MuFlo 

struct LeafHeaderTitleView: View {

    @ObservedObject var leafVm: LeafVm
    let inset: CGFloat
    var leafTitle: String { leafVm.leafTitle() }
    var size: CGSize {
        let w = leafVm.panelVm.titleSize.width + inset
        let h = leafVm.panelVm.titleSize.height
        return CGSize(width: max(0,w), height: max(0,h))
    }

    init(_ leafVm: LeafVm,
         inset: CGFloat) {
        self.leafVm = leafVm
        self.inset = inset
    }
    var body: some View {

        Text(leafTitle)
            .scaledToFit()
            .allowsTightening(true)
            .font(Font.system(size: 14, design: .default))
            .minimumScaleFactor(0.5)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 1.0)
    }
}

struct LeafHeaderDeltaView: View {

    let leafVm: LeafVm

    @State var originRotate : Double
    var originOpacity: Double  { leafVm.origin ? 1 : 0 }
    var deltaOpacity : Double  { leafVm.origin ? 0 : 1 }

    init(_ leafVm: LeafVm) {
        self.leafVm = leafVm
        self.originRotate = leafVm.origin ? .pi : 0
    }

    #if os(watchOS)
    /// Smaller width on watch so the X runway placement stays aligned with
    /// the iOS layout proportionally.
    private let dim: CGFloat = Menu.diameter
    #else
    private let dim: CGFloat = 30
    #endif

    var body: some View {
        Button {
            leafVm.updateNodeValue(Visitor(0,.user))
        } label: {
            ZStack {
                // SwiftUI Image(_:bundle:) loads the asset on all platforms.
                Image("icon.flip.delta", bundle: .main)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: dim, height: dim)
                    .foregroundColor(.white)
                    .opacity(deltaOpacity)
                    .rotationEffect(.radians(originRotate + .pi))

                Image("icon.flip.original", bundle: .main)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: dim, height: dim)
                    .foregroundColor(.white)
                    .opacity(originOpacity)
                    .rotationEffect(.radians(originRotate))
            }
        }
        .buttonStyle(.plain)  // remove watchOS default capsule chrome
        .onChange(of: leafVm.origin) {
            originRotate += .pi
        }
        .frame(width: dim, height: dim)
        .animation(Animate(1.0), value: deltaOpacity)
        .animation(Animate(1.0), value: originOpacity)
        .animation(Animate(1.0), value: originRotate)
    }
}
