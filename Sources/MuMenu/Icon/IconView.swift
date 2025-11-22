// created by musesum on 10/17/21.

import SwiftUI

struct IconView: View {

    @Environment(\.colorScheme) var colorScheme // darkMode
    @ObservedObject var nodeVm: NodeVm

    let icon: Icon
    var isOn: Bool {
        if let leaf = nodeVm as? LeafVm,
           let thumb = leaf.runways.thumb() {
            return thumb.value.x > 0
        }
         return true
    }
    let runwayType: LeafRunwayType
    var title: String { nodeVm.menuTree.flo.name }
    var iconName: String { isOn ? icon.nameOn  : icon.nameOff  }
    var iconImage: UIImage?  { isOn ? icon.imageOn : icon.imageOff }

    var spotlight: Bool { nodeVm.spotlight }
    var fillColor = Color(white: 0).opacity(0.62)
    var strokeColor: Color { spotlight ? .white : Color(white: 0.7) }
    var strokeWidth: CGFloat { spotlight ? 5.0 : 1.0 }

    init(_ nodeVm: NodeVm,
         _ icon: Icon,
         _ runwayType: LeafRunwayType) {
        self.nodeVm = nodeVm
        self.icon = icon
        self.runwayType = runwayType
    }

    var body: some View {
        ZStack {

            if icon.typeOn != .cursor {

                RoundedRectangle(cornerRadius: Menu.cornerRadius)
                    .fill(fillColor)
                    .overlay(RoundedRectangle(cornerRadius:  Menu.cornerRadius)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        .background(.clear)
                    )

                    .hoverEffect()
                    .cornerRadius(Menu.cornerRadius)

            }
            switch runwayType {
            case .runX, .runY, .runU, .runV, .runW, .runZ, .runS, .runT:
                IconSideView(runwayType, strokeColor)
            default:
                switch icon.typeOn {
                case .none: IconTitleView(title: title, color: strokeColor)
                case .text: IconTitleView(title: iconName, color: strokeColor)
                case .cursor:

                    if let uiImage = UIImage(named: iconName) {
                        Image(uiImage: uiImage).resizable() }

                case .image:

                    if let image = iconImage {
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .padding(geo.size.width * 0.1)
                        }
                    } else {
                        IconTitleView(title: title, color: strokeColor)
                    }
                case .svg:

                    if let image = iconImage {
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .padding(geo.size.width * 0.15)
                                .colorInvert()
                        }
                    } else {
                        IconTitleView(title: title, color: strokeColor)
                            .shadow(color: .black, radius: 1)
                    }
                case .symbol:

                    Image(systemName: iconName)
                        .scaledToFit()
                        .padding(1)
                }
            }
        }
        .allowsHitTesting(true)
    }
}

struct IconTitleView: View {

    let title: String
    var color: Color

    var body: some View {

            Text(title)
                .scaledToFit()
                .padding(1)
                .minimumScaleFactor(0.01)
                .foregroundColor(color)
                .animation(Menu.flashAnim, value: color)
    }
}

private struct IconSideView: View {

    let runwayType: LeafRunwayType
    let color: Color
    var title: String {
        switch runwayType {
        case .runX: "x"
        case .runY: "y"
        case .runU: "u"
        case .runV: "v"
        case .runW: "w"
        case .runZ: "z"
        case .runS: "s"
        case .runT: "t"
        default: "?"
         }

    }
    init(_ runwayType: LeafRunwayType,
         _ color: Color) {
        self.runwayType = runwayType
        self.color = color
    }
    var body: some View {
            Text(title)
                .scaledToFit()
                .padding(1)
                .minimumScaleFactor(0.01)
                .foregroundColor(color)
                .animation(Menu.flashAnim, value: color)
                .shadow(color: .black, radius: 1)
    }
}
