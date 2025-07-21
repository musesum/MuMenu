// created by musesum on 7/16/25

import SwiftUI
import MuFlo

public struct MenuViewing: OptionSet, Sendable {
    public let rawValue: Int

    public static let canvas = MenuViewing(rawValue: 1 << 0)
    public static let menu   = MenuViewing(rawValue: 1 << 1)
    public static let hands  = MenuViewing(rawValue: 1 << 2)
    public static let left   = MenuViewing(rawValue: 1 << 3)
    public static let right  = MenuViewing(rawValue: 1 << 4)
    public static let glass  = MenuViewing(rawValue: 1 << 5)

    var canvas : Bool { contains(.canvas) }
    var menu   : Bool { contains(.menu  ) }
    var hands  : Bool { contains(.hands ) }
    var left   : Bool { contains(.left  ) }
    var right  : Bool { contains(.right ) }
    var glass  : Bool { contains(.glass ) }

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
open class MenuState: ObservableObject {

    private var glass˚ : Flo?
    @Published public var glass = true

#if !os(visionOS)
    public init(_ root˚: Flo) {
        glass˚ = root˚.bind("more.settings.glass") { f,_ in
            self.glass = f.bool
        }
    }
#else
    private var left˚  : Flo?
    private var right˚ : Flo?
    public var left = false
    public var right = false

    public init(_ root˚: Flo) {
        let menu = root˚.bind("hand.menu")

        left˚  = menu.bind("left" ) { f,_ in
            self.leftThumbTip(f.bool)
        }
        right˚ = menu.bind("right") { f,_ in
            self.rightThumbTip(f.bool)
        }
    }
    func leftThumbTip(_ new: Bool) {
        if new != left {
            PrintLog("left: \(left) -> \(new)")
            left = new
        }
    }
    func rightThumbTip(_ new: Bool) {
        if new != right {
            PrintLog("right: \(right) -> \(new)")
            right = new
        }
    }
#endif
}
