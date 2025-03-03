// created by musesum on 3/27/24

import SwiftUI

/// title showing position of control
struct LeafHeaderView: View {

    @ObservedObject var leafVm: LeafVm

    init(_ leafVm: LeafVm) {
        self.leafVm = leafVm
    }
    var body: some View {

        HStack(spacing: 0) {

            switch leafVm.nodeType {

            case .xy,.xyz:
                Spacer()
                LeafHeaderTitleView(leafVm, inset: -64)
                LeafHeaderDeltaView(leafVm)


            case .arch:
                LeafHeaderPlusView(leafVm)
                LeafHeaderTitleView(leafVm, inset: -64)
                Spacer()

            default:
                LeafHeaderTitleView(leafVm)
            }
        }
    }
}
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

struct LeafHeaderPlusView: View {

    let leafVm: LeafVm

    init(_ leafVm: LeafVm) {
        self.leafVm = leafVm
    }
    
    var body: some View {
        
        Button {
            leafVm.tapPlusButton()
        } label: {
            Image(systemName: "plus.circle")
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
    }
}
struct LeafHeaderDeltaView: View {

    let leafVm: LeafVm

    @State var originRotate : Double
    var originImage  : UIImage { UIImage.named("icon.flip.original")! }
    var originOpacity: Double  { leafVm.changed ? 0 : 1 }
    var deltaImage   : UIImage { UIImage.named("icon.flip.delta")! }
    var deltaOpacity : Double  { leafVm.changed ? 1 : 0 }

    init(_ leafVm: LeafVm) {
        self.leafVm = leafVm
        self.originRotate = leafVm.changed ? .pi : 0
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
            leafVm.resetOrigin()
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
        .onChange(of: leafVm.changed) {
            originRotate += .pi
        }
        .frame(width: 30, height: 30)
        .animation(Layout.animateDebug, value: deltaOpacity)
        .animation(Layout.animateDebug, value: originOpacity)
        .animation(Layout.animateDebug, value: originRotate)
    }
}
