// created by musesum on 10/31/21.

import SwiftUI

func Animate(_ sec: TimeInterval) -> Animation {
    .easeInOut(duration: sec)
}

public enum Menu {

    static let diameter: CGFloat = 40
    static let diameter2: CGFloat = 48 // always diameter + padding2
    static let radius: CGFloat = 20
    static let padding: CGFloat = 4
    static let padding2: CGFloat = 8 // always padding * 2
    static var cornerRadius: CGFloat { radius + padding }
    static let labelSize = CGSize(width: diameter+8, height: diameter-8)
    /// distance from center while inside node
    static let insideNode: CGFloat = 24

    static let iconRing = "icon.ring"
    static let iconLogo = "icon.logo"
    static let lagStep = TimeInterval(1.0/32.0) // sixteenth of a second
    static let panelFill = Color(white: 0.01, opacity: 0.15)
    static func togColor(_ spot: Bool) -> Color { return spot ? .white : Color(white: 0.4) }


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
        let color = (high
                     ? Color(white: 1.0, opacity: 0.8)
                     : Color(white: 0.8, opacity: 0.7))
        return color
    }
    static func strokeWidth(_ high: Bool) -> CGFloat {
        return(high ? 2.0 : 1.2)
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
