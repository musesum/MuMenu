// created by musesum on 10/17/21.

import SwiftUI


struct IconView: View {

    @Environment(\.colorScheme) var colorScheme // darkMode
    @ObservedObject var nodeVm: NodeVm
    let icon: Icon
    let runwayType: LeafRunwayType

    var title: String {
        switch runwayType {
        case .runX   : return "x"
        case .runY   : return "y"
        case .runZ   : return "z"
        default   : return nodeVm.menuTree.title
        }
    }
    var named: String { nodeVm.menuTree.icon.icoName }

    var spotlight: Bool { nodeVm.spotlight }
    var stroke: Color { spotlight ? .white : Color(white: 0.7) }
    var fill = Color(white: 0.25) 
    var width: CGFloat { spotlight ? 3.0 : 1.0 }
    
    init(_ nodeVm: NodeVm, 
         _ icon: Icon,
         _ runwayType: LeafRunwayType) {
        self.nodeVm = nodeVm
        self.icon = icon
        self.runwayType = runwayType
    }

    var body: some View {
        ZStack {
            if icon.iconType != .cursor {
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .fill(fill)
                    .overlay(RoundedRectangle(cornerRadius:  Layout.cornerRadius)
                        .stroke(stroke, lineWidth: width)
                        .background(.clear)
                    )
                    .shadow(color: .black, radius: 1)
            }
            switch runwayType {
            case .runX:
                IconTitleView(title: "x", color: stroke)
                    .shadow(color: .black, radius: 1)
            case .runY:
                IconTitleView(title: "y", color: stroke)
                    .shadow(color: .black, radius: 1)
            case .runZ:
                IconTitleView(title: "z", color: stroke)
                    .shadow(color: .black, radius: 1)
            default:

                switch icon.iconType {
                case .none: IconTitleView(title: title, color: stroke)
                case .text: IconTitleView(title: named, color: stroke)
                case .cursor:

                    if let uiImage = UIImage(named: nodeVm.menuTree.icon.icoName) {
                        Image(uiImage: uiImage).resizable() }

                case .image:

                    if let image = icon.image {
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .padding(geo.size.width * 0.1)
                        }
                    } else {
                        IconTitleView(title: title, color: stroke)
                    }
                case .svg:

                    if let image = icon.image {
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .padding(geo.size.width * 0.15)
                                .colorInvert()
                        }
                    } else {
                        IconTitleView(title: title, color: stroke)
                            .shadow(color: .black, radius: 1)
                    }
                case .symbol:

                    if colorScheme == .dark {
                        Image(systemName: nodeVm.menuTree.icon.icoName)
                            .scaledToFit()
                            .padding(1)
                    } else {
                        Image(systemName: nodeVm.menuTree.icon.icoName)
                            .colorInvert()
                            .scaledToFit()
                            .padding(1)
                    }
                }
            }
        }
        .allowsHitTesting(true)
    }
}

private struct IconTitleView: View {

    let title: String
    var color: Color

    var body: some View {
        Text(title)
            .scaledToFit()
            .padding(1)
            .minimumScaleFactor(0.01)
            .foregroundColor(color)
            .animation(Layout.flashAnim, value: color)
    }
}
