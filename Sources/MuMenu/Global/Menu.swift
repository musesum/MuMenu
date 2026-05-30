// created by musesum on 10/31/21.

import SwiftUI

func Animate(_ sec: TimeInterval) -> Animation {
    .easeInOut(duration: sec)
}

public enum Menu {

#if os(watchOS)
    public static let diameter: CGFloat = 13
    public static let diameter2: CGFloat = 17
    public static let radius: CGFloat = 6
    public static let padding: CGFloat = 2
    public static let padding2: CGFloat = 4
    public static var cornerRadius: CGFloat { radius + padding }
    public static let labelSize = CGSize(width: diameter+4, height: diameter-4)
    public static let insideNode: CGFloat = 8
#else
    public static let diameter: CGFloat = 40
    public static let diameter2: CGFloat = 48
    public static let radius: CGFloat = 20
    public static let padding: CGFloat = 4
    public static let padding2: CGFloat = 8
    public static var cornerRadius: CGFloat { radius + padding }
    public static let labelSize = CGSize(width: diameter+8, height: diameter-8)
    public static let insideNode: CGFloat = 24
#endif

    static let iconRing = "icon.ring"
//    static let iconLogo = "icon.logo"
    static let lagStep = TimeInterval(1.0/32.0) // sixteenth of a second
    static let panelFill = Color(white: 0.01, opacity: 0.15)
    static func togColor(_ spot: Bool) -> Color { return spot ? .white : Color(white: 0.4) }

    public static func touchWidth(_ geo: GeometryProxy) -> CGFloat {
        geo.size.width +
        geo.safeAreaInsets.leading +
        geo.safeAreaInsets.trailing
    }
    public static func touchHeight(_ geo: GeometryProxy) -> CGFloat {
        geo.size.height +
        geo.safeAreaInsets.top +
        geo.safeAreaInsets.bottom
    }
    public static func touchOffset(_ geo: GeometryProxy) -> CGSize {
        CGSize(width:  -geo.safeAreaInsets.leading,
               height: -geo.safeAreaInsets.top)
    }


#if os(visionOS) || os(iPadOS)
    public static let margin = CGFloat(16)
    public static func offset(_ menuCorner: MenuCorner) -> CGSize {
        switch menuCorner {
        case .NW: return CGSize(width:  margin, height:  margin)
        case .NE: return CGSize(width: -margin, height:  margin)
        case .SW: return CGSize(width:  margin, height: -margin)
        case .SE: return CGSize(width: -margin, height: -margin)
        case .none: return .zero
        }
    }
#else
    public static func offset(_ menuCorner: MenuCorner) -> CGSize {
        .zero
    }
#endif

    /// quick animation for fla
    static var flashAnim: Animation { .easeInOut(duration: 0.20) }

    static func strokeColor(_ high: Bool) -> Color {
        #if os(watchOS)
        // Match node IconView stroke palette on watchOS — white spotlit, mid-gray otherwise.
        return high ? .white : Color(white: 0.5)
        #else
        let color = (high
                     ? Color(white: 1.0, opacity: 0.8)
                     : Color(white: 0.8, opacity: 0.7))
        return color
        #endif
    }
    static func strokeWidth(_ high: Bool) -> CGFloat {
        #if os(watchOS)
        return 1.0  // Match node IconView stroke thickness.
        #else
        return(high ? 2.0 : 1.2)
        #endif
    }

    static func tapColor(_ high: Bool) -> Color {
        let color = (high
                     ? Color(white: 1.0, opacity: 0.8)
                     : Color(white: 0.6, opacity: 0.8))
        return color
    }
    static func tweenColor(_ high: Bool) -> Color {
        let color = (high
                     ? Color(white: 0.8, opacity: 0.7)
                     : Color(white: 0.5, opacity: 0.7))
        return color
    }
    static func thumbColor(_ thumb: CGFloat) -> Color {
        let color = (thumb > 0
                     ? Color(white: 1.0, opacity: 1.00)
                     : Color(white: 0.5, opacity: 0.90))
        return color
    }
}
