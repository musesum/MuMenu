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

    private var left˚  : Flo?
    private var right˚ : Flo?
    private var glass˚ : Flo?

    public var left = true
    public var right = true
    @Published public var glass = true

    public init(_ root˚: Flo) {
        let menu = root˚.bind("hand.menu")
        left˚  = menu.bind("left" ) { f,_ in self.left  = f.bool }
        right˚ = menu.bind("right") { f,_ in self.right = f.bool }
        glass˚ = root˚.bind("more.settings.glass") { f,_ in
            self.glass = f.bool
        }
    }
}
