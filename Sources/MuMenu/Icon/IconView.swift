// created by musesum on 10/17/21.

import SwiftUI
#if !os(watchOS)
import UIKit
#endif

#if os(watchOS)
/// Asset-name → SF Symbol mapping for the MuSky SVG icon set that ships only
/// as svg assets in MuSky.bundle (iOS-only). On watchOS these get rendered as
/// SF Symbols instead, falling back to first-letter glyphs for unmapped names.
private let svgToSFSymbol: [String: String] = [
    "icon.canvas":   "paintpalette",
    "icon.brush":    "paintbrush.pointed",
    "icon.plato":    "cube",
    "icon.cell":     "circle.grid.3x3.fill",
    "icon.cellular.automata": "circle.grid.3x3.fill",
    "icon.camera":   "camera",
    "icon.more":     "ellipsis",
    "icon.chat":     "bubble.left",
    "icon.midi":     "pianokeys",
    "icon.tape":     "recordingtape",
    "icon.mic":      "mic",
    "icon.archive":  "archivebox",
    "icon.music":    "music.note",
    "icon.draw":     "scribble",
    "icon.pipe":     "circle.dotted.circle",
    "icon.hand":     "hand.raised",
    "icon.sky":      "cloud.fill",
    "icon.skel":     "figure.stand",
    "icon.iris":     "circle.dashed",
    "icon.mark":     "checkmark.square",
    "icon.size":     "arrow.up.left.and.arrow.down.right",
    "icon.colors":   "paintpalette.fill",
    "icon.color":    "paintpalette.fill",
]
#endif

public struct IconView: View {

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
    #if !os(watchOS)
    var iconImage: UIImage?  { isOn ? icon.imageOn : icon.imageOff }
    #endif

    var spotlight: Bool { nodeVm.spotlight }
    var fillColor = Color(white: 0).opacity(0.62)
    #if os(watchOS)
    // watchOS: solid stroke, white when spotlit and mid-gray otherwise.
    // Thinner than iOS — small screen needs lighter strokes.
    var strokeColor: Color { spotlight ? .white : Color(white: 0.5) }
    var strokeWidth: CGFloat { spotlight ? 0.8 : 0.4 }
    #else
    var strokeColor: Color { spotlight ? .white : Color(white: 0.7) }
    var strokeWidth: CGFloat { spotlight ? 5.0 : 1.0 }
    #endif

    public init(_ nodeVm: NodeVm,
                _ icon: Icon,
                _ runwayType: LeafRunwayType) {
        self.nodeVm = nodeVm
        self.icon = icon
        self.runwayType = runwayType
    }

    public var body: some View {
        ZStack {

            if icon.typeOn != .cursor {
                #if os(watchOS)
                Circle()
                    .fill(fillColor)
                    .overlay(Circle().stroke(strokeColor, lineWidth: strokeWidth))
                #else
                RoundedRectangle(cornerRadius: Menu.cornerRadius)
                    .fill(fillColor)
                    .overlay(RoundedRectangle(cornerRadius:  Menu.cornerRadius)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        .background(.clear)
                    )
                    .hoverEffect()
                    .cornerRadius(Menu.cornerRadius)
                #endif
            }
            switch runwayType {
            case .runX, .runY, .runU, .runV, .runW, .runZ, .runS, .runT:
                IconSideView((nodeVm as? LeafVm)?.thumbLabel(runwayType) ?? runwayType.label,
                             strokeColor)
            default:
                switch icon.typeOn {
                case .none: IconTitleView(title: title, color: strokeColor)
                case .text: IconTitleView(title: iconName, color: strokeColor)
                #if !os(watchOS)
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
                #else
                case .cursor:
                    Circle().stroke(strokeColor, lineWidth: 1.0)
                case .image, .svg:
                    // Render the actual SVG asset from the host watch app's
                    // bundled Sky.xcassets. `.renderingMode(.template)` lets
                    // `.foregroundColor` tint the strokes; without it the SVG
                    // ink color (often near-white) blends into the strokeColor
                    // and disappears.
                    Image(iconName, bundle: .main)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .padding(2)
                        .foregroundColor(strokeColor)
                #endif
                case .symbol:

                    Image(systemName: iconName)
                        #if os(watchOS)
                        // Match the SVG `.image`/.svg case so the outer circle
                        // and inner glyph proportion are consistent across all
                        // icon types (was `.font(size: 6) + padding(4)` which
                        // shrank the symbol relative to SVG icons).
                        .resizable()
                        .scaledToFit()
                        .padding(2)
                        .foregroundColor(strokeColor)
                        #else
                        .scaledToFit()
                        .padding(1)
                        #endif
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

    let title: String
    let color: Color
    init(_ title: String,
         _ color: Color) {
        self.title = title
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
