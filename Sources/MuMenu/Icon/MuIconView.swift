// Created by warren on 10/17/21.

import SwiftUI

struct MuIconView: View {

    @ObservedObject var nodeVm: MuNodeVm
    let icon: MuIcon
    var color: Color { nodeVm.spotlight ? .white : .gray }
    var fill: Color { icon.type == .cursor ? .clear : .black}
    var width: CGFloat { nodeVm.spotlight ? 2.0 : 0.5 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: nodeVm.panelVm.cornerRadius)
                .fill(fill)

            RoundedRectangle(cornerRadius: nodeVm.panelVm.cornerRadius)
                .stroke(color, lineWidth: width)
                .animation(Layout.flashAnim, value: color)
                .animation(Layout.flashAnim, value: width)
                .background(Color.clear)

            switch icon.type {

                case .none:

                    MuIconTextView(icon: icon,
                                   text: nodeVm.node.title,
                                   color: color)
                case .abbrv:

                    MuIconTextView(icon: icon,
                                   text: nodeVm.node.icon.named,
                                   color: color)
                case .cursor:

                    if let uiImage = UIImage(named: nodeVm.node.icon.named) {
                        Image(uiImage: uiImage)
                            .resizable()
                    }

                case .image:

                    if let uiImage = UIImage(named: nodeVm.node.icon.named) {
                        GeometryReader { geo in
                            Image(uiImage: uiImage)
                                .resizable()
                                .padding(geo.size.width * 0.1)
                        }
                    } else {
                        MuIconTextView(icon: icon,
                                       text: nodeVm.node.title,
                                       color: color)
                    }
                case .symbol:

                    Image(systemName: nodeVm.node.icon.named)
                        .scaledToFit()
                        .padding(1)
            }
        }
    }
}

private struct MuIconTextView: View {

    let icon: MuIcon
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
