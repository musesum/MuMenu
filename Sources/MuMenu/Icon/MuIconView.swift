// Created by warren on 10/17/21.

import SwiftUI

struct MuIconView: View {

    @Environment(\.colorScheme) var colorScheme // darkMode
    @ObservedObject var nodeVm: MuNodeVm
    let icon: MuIcon
    var color: Color { nodeVm.spotlight ? .white : Color(white:0.7) }
    var fill: Color { icon.iconType == .cursor ? .clear : .black }
    var width: CGFloat { nodeVm.spotlight ? 3.0 : 1.0 }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius:  Layout.cornerRadius)
                    .stroke(color, lineWidth: width)
                    .background(Color.clear))

            switch icon.iconType {

                case .none: MuIconTextView(text: nodeVm.node.title,
                                           color: color)
                    
                case .text: MuIconTextView(text: nodeVm.node.icon.named,
                                           color: color)
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
                        MuIconTextView(text: nodeVm.node.title,
                                       color: color)
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
                        MuIconTextView(text: nodeVm.node.title,
                                       color: color)
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
    }
}

private struct MuIconTextView: View {

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
