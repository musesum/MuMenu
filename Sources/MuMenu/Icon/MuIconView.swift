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
                    Text(nodeVm.node.name)
                        .scaledToFit()
                        .padding(1)
                        .minimumScaleFactor(0.01)
                        .foregroundColor(color)
                        .animation(Layout.flashAnim, value: color)
                case .abbrv:
                    Text(nodeVm.node.icon.named)
                        .scaledToFit()
                        .padding(1)
                        .minimumScaleFactor(0.01)
                        .foregroundColor(color)
                        .animation(Layout.flashAnim, value: color)
                case .cursor,.image:
                    if let uiImage = UIImage(named: nodeVm.node.icon.named) {
                        Image(uiImage: uiImage)
                            .resizable()
                    } else {
                        Text(nodeVm.node.name)
                            .scaledToFit()
                            .padding(1)
                            .minimumScaleFactor(0.01)
                            .foregroundColor(color)
                            .animation(Layout.flashAnim, value: color)
                    }
                case .symbol:
                    Image(systemName: nodeVm.node.icon.named)
                        .scaledToFit()
                        .padding(1)
            }
        }
    }
}
