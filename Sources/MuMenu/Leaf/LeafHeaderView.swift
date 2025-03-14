// created by musesum on 3/27/24

import SwiftUI


struct LeafHeaderTitleView: View {

    @ObservedObject var leafVm: LeafVm
    let inset: CGFloat
    var leafTitle: String { leafVm.leafTitle() }
    var size: CGSize { leafVm.panelVm.titleSize }

    init(_ leafVm: LeafVm,
         inset: CGFloat = 0) {
        self.leafVm = leafVm
        self.inset = inset
    }
    var body: some View {

        Text(leafTitle)
            .scaledToFit()
            .allowsTightening(true)
            .font(Font.system(size: 14, design: .default))
            .minimumScaleFactor(0.01)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 1.0)
            .frame(width:  size.width + inset,
                   height: size.height,
                   alignment: .center)
    }
}

struct LeafHeaderDeltaView: View {

    let leafVm: LeafVm

    @State var originRotate : Double
    var originImage  : UIImage { UIImage.named("icon.flip.original")! }
    var originOpacity: Double  { leafVm.origin ? 1 : 0 }
    var deltaImage   : UIImage { UIImage.named("icon.flip.delta")! }
    var deltaOpacity : Double  { leafVm.origin ? 0 : 1 }

    init(_ leafVm: LeafVm) {
        self.leafVm = leafVm
        self.originRotate = leafVm.origin ? .pi : 0
    }

    func image(_ name: String) -> UIImage? {

        if let img = UIImage(named: name) {
            return img
        } else {
            for bundle in Icon.altBundles {
                if let img =  UIImage(named: name, in: bundle, with: nil) {
                    return img
                }
            }
        }
        return nil
    }

    var body: some View {

        Button {
            leafVm.touchedOrigin()
        } label: {
            ZStack {
                Image(uiImage: deltaImage)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .opacity(deltaOpacity)
                    .rotationEffect(.radians(originRotate + .pi))

                Image(uiImage: originImage)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .opacity(originOpacity)
                    .rotationEffect(.radians(originRotate))
            }
        }
        .onChange(of: leafVm.origin) {
            originRotate += .pi
        }
        .frame(width: 30, height: 30)
        .animation(Animate(1.0), value: deltaOpacity)
        .animation(Animate(1.0), value: originOpacity)
        .animation(Animate(1.0), value: originRotate)
    }
}
