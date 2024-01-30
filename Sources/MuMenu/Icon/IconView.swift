// created by musesum on 10/17/21.

import SwiftUI


struct IconView: View {

    @Environment(\.colorScheme) var colorScheme // darkMode
    @ObservedObject var nodeVm: NodeVm
    let icon: Icon

    var title: String { nodeVm.node.title }
    var named: String { nodeVm.node.icon.named }

    var spotlight: Bool { nodeVm.spotlight }
    var stroke: Color { spotlight ? .white : Color(white: 0.7) }
    var fill: Color { spotlight ? Color(white: 0.30) : Color(white: 0.15)  }
    var width: CGFloat { spotlight ? 3.0 : 1.0 }
    
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
            switch icon.iconType {

            case .none: IconTextView(text: title, color: stroke)
            case .text: IconTextView(text: named, color: stroke)
            case .cursor:

                if let uiImage = UIImage(named: nodeVm.node.icon.named) {
                    Image(uiImage: uiImage).resizable() }

            case .image:

                if let image = icon.image {
                    GeometryReader { geo in
                        Image(uiImage: image)
                            .resizable()
                            .padding(geo.size.width * 0.1)
                    }
                } else {
                    IconTextView(text: nodeVm.node.title, color: stroke)
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
                    IconTextView(text: nodeVm.node.title, color: stroke)
                        .shadow(color: .black, radius: 1)
                }
            case .symbol:

                if colorScheme == .dark {
                    Image(systemName: nodeVm.node.icon.named)
                        .scaledToFit()
                        .padding(1)
                } else {
                    Image(systemName: nodeVm.node.icon.named)
                        .colorInvert()
                        .scaledToFit()
                        .padding(1)
                }
            }
        }
        .allowsHitTesting(true)
        .hoverEffect()
    }
}

private struct IconTextView: View {

    let text: String
    var color: Color

    var body: some View {
        Text(text)
            .scaledToFit()
            .padding(1)
            .minimumScaleFactor(0.01)
            .foregroundColor(color)
            .animation(Layout.flashAnim, value: color)
    }
}
