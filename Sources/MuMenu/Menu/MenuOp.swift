// created by musesum on 6/14/25
import SwiftUI

public enum MenuCorner {
    case none, upLeft, upRight, downLeft, downRight
    var icon: String {
        switch self {
        case .none      : "⬜︎"
        case .upLeft    : "◤"
        case .upRight   : "◥"
        case .downLeft  : "◣"
        case .downRight : "◥"
        }
    }
}

public enum MenuCornerAxis: String {
    case none, ULV, ULH, URV, URH, DLV, DLH, DRV, DRH
}

public enum MenuProgression {
    case VL, // vertical leftward
         VR, // vertical rightward
         HU, // horiontal upward
         HD  // horizontal downward
}

public struct MenuType: OptionSet, Codable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public init(_ names: String) {
        var value = 0
        for char in names {
            if let op = MenuType.charOp[char] {
                value |= op.rawValue
            }
        }
        self.init(rawValue: value)
    }

    public static let U  = MenuType(rawValue: 1 << 0) // up
    public static let D  = MenuType(rawValue: 1 << 1) // down
    public static let L  = MenuType(rawValue: 1 << 2) // left
    public static let R  = MenuType(rawValue: 1 << 3) // right
    public static let Z0 = MenuType(rawValue: 1 << 4) // near
    public static let Z1 = MenuType(rawValue: 1 << 5) // far
    public static let H  = MenuType(rawValue: 1 << 6) // hori
    public static let V  = MenuType(rawValue: 1 << 7) // vert

    public static let UL = MenuType("UL")
    public static let UR = MenuType("UR")
    public static let DL = MenuType("DL")
    public static let DR = MenuType("DR")

    public static let ULV = MenuType("ULV")
    public static let ULH = MenuType("ULH")
    public static let URV = MenuType("URV")
    public static let URH = MenuType("URH")
    public static let DLV = MenuType("DLV")
    public static let DLH = MenuType("DLH")
    public static let DRV = MenuType("DRV")
    public static let DRH = MenuType("DRH")

    public static let VHLR = MenuType("VHLR")

    var _U  : Int { self.rawValue & MenuType.U .rawValue }
    var _D  : Int { self.rawValue & MenuType.D .rawValue }
    var _L  : Int { self.rawValue & MenuType.L .rawValue }
    var _R  : Int { self.rawValue & MenuType.R .rawValue }
    var _Z0 : Int { self.rawValue & MenuType.Z0.rawValue }
    var _Z1 : Int { self.rawValue & MenuType.Z1.rawValue }
    var _H  : Int { self.rawValue & MenuType.H .rawValue }
    var _V  : Int { self.rawValue & MenuType.V .rawValue }

    public var up       : Bool { self.contains(.U ) }
    public var down     : Bool { self.contains(.D ) }
    public var left     : Bool { self.contains(.L ) }
    public var right    : Bool { self.contains(.R ) }
    public var near     : Bool { self.contains(.Z0) }
    public var far      : Bool { self.contains(.Z1) }
    public var horizon  : Bool { self.contains(.H ) }
    public var vertical : Bool { self.contains(.V ) }

    public var chiral: MenuType { MenuType(rawValue: self.rawValue & (MenuType.L.rawValue | MenuType.R.rawValue))}


    public var corner: MenuCorner {
        let UDLR = MenuType([.U,.D,.L,.R]).rawValue
        switch self.rawValue & UDLR {
        case (_U + _R) : return .upRight
        case (_U + _L) : return .upLeft
        case (_D + _R) : return .downRight
        case (_D + _L) : return .downLeft
        default        : return .none
        }
    }

    public var axis: MenuCorner {
        let UD = MenuType([.U,.D]).rawValue
        switch self.rawValue & UD {

        case (_U + _R) : return .upRight
        case (_U + _L) : return .upLeft
        case (_D + _R) : return .downRight
        case (_D + _L) : return .downLeft
        default        : return .none
        }
    }
    public var cornerAxis: MenuCornerAxis {
        let UDLRVH = MenuType([.U,.D,.L,.R,.V,.H]).rawValue
        switch self.rawValue & UDLRVH {
        case (_U + _L + _V) : return .ULV
        case (_U + _L + _H) : return .ULH
        case (_U + _R + _V) : return .URV
        case (_U + _R + _H) : return .URH
        case (_D + _L + _V) : return .DLV
        case (_D + _L + _H) : return .DLH
        case (_D + _R + _V) : return .DRV
        case (_D + _R + _H) : return .DRH
        default             : return .none
        }
    }
    public var icon: String {
        let UDLRVH = MenuType([.U,.D,.L,.R,.V,.H]).rawValue
        switch self.rawValue & UDLRVH {
        case (_U + _L + _V) : return "◤❚"
        case (_U + _L + _H) : return "◤▬"
        case (_U + _R + _V) : return "❚◥"
        case (_U + _R + _H) : return "▬◥"
        case (_D + _L + _V) : return "◣❚"
        case (_D + _L + _H) : return "◣▬"
        case (_D + _R + _V) : return "❚◢"
        case (_D + _R + _H) : return "▬◢"
        default             : return "⬜︎"
        }
    }
    public var progression: MenuProgression {
        return (vertical
                ? (left ? .VL : .VR)
                : (up ? .HU : .HD))
    }
    public static let charOp: [Character: MenuType] = [
        "U": .U  , "D": .D  ,
        "L": .L  , "R": .R  ,
        "H": .H  , "V": .V  ,
        "0": .Z0 , "1": .Z1 ,
    ]

    public var key: String {
        MenuType.charOp.compactMap { (char, op) in
            self.contains(op) ? String(char) : nil
        }.joined()
    }
    public var description: String {
        let mapping: [(MenuType, String)] = [
            (.U  , "up"     ), (.D  , "down"     ),
            (.L  , "left"   ), (.R  , "right"    ),
            (.Z0 , "near"   ), (.Z1 , "far"      ),
            (.H  , "horizon"), (.V  , "vertical" )
        ]

        let matched = mapping.compactMap { (flag, name) in
            self.contains(flag) ? name : nil
        }

        if matched.count == 1, let single = matched.first {
            return single
        } else if matched.isEmpty {
            return "none"
        } else {
            return "[" + matched.joined(separator: ", ") + "]"
        }
    }

    public func contains(_ names: String) -> Bool {
        for char in names {
            guard let op = MenuType.charOp[char], self.contains(op) else {
                return false
            }
        }
        return true
    }

    static func flipUpperLower(_ oldOp: Int) -> Int {

        return oldOp ^ MenuType([.U, .D]).rawValue
    }

    var hAlign: HorizontalAlignment { self.left ? .leading : .trailing }
    var vAlign: VerticalAlignment   { self.up ? .top : .bottom }
    var alignment: Alignment { Alignment(horizontal: hAlign, vertical: vAlign) }

}

