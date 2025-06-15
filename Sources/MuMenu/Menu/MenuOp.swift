// created by musesum on 6/14/25
import SwiftUI

public enum MenuCorner {
    case none, upLeft, upRight, downLeft, downRight
}
public enum MenuCornerAxis {
    case none, ULV, ULH, URV, URH, DLV, DLH, DRV, DRH
}


public struct MenuOp: OptionSet, Codable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public init(_ names: String) {
        var value = 0
        for char in names {
            if let op = MenuOp.charOp[char] {
                value |= op.rawValue
            }
        }
        self.init(rawValue: value)
    }

    public static let U  = MenuOp(rawValue: 1 << 0) // up
    public static let D  = MenuOp(rawValue: 1 << 1) // down
    public static let L  = MenuOp(rawValue: 1 << 2) // left
    public static let R  = MenuOp(rawValue: 1 << 3) // right
    public static let Z0 = MenuOp(rawValue: 1 << 4) // near
    public static let Z1 = MenuOp(rawValue: 1 << 5) // far
    public static let H  = MenuOp(rawValue: 1 << 6) // hori
    public static let V  = MenuOp(rawValue: 1 << 7) // vert

    var _U  : Int { self.rawValue & MenuOp.U .rawValue }
    var _D  : Int { self.rawValue & MenuOp.D .rawValue }
    var _L  : Int { self.rawValue & MenuOp.L .rawValue }
    var _R  : Int { self.rawValue & MenuOp.R .rawValue }
    var _Z0 : Int { self.rawValue & MenuOp.Z0.rawValue }
    var _Z1 : Int { self.rawValue & MenuOp.Z1.rawValue }
    var _H  : Int { self.rawValue & MenuOp.H .rawValue }
    var _V  : Int { self.rawValue & MenuOp.V .rawValue }

    public var up       : Bool { self.contains(.U ) }
    public var down     : Bool { self.contains(.D ) }
    public var left     : Bool { self.contains(.L ) }
    public var right    : Bool { self.contains(.R ) }
    public var near     : Bool { self.contains(.Z0) }
    public var far      : Bool { self.contains(.Z1) }
    public var horizon  : Bool { self.contains(.H ) }
    public var vertical : Bool { self.contains(.V ) }

    public var chiral: MenuOp { MenuOp(rawValue: self.rawValue & (MenuOp.L.rawValue | MenuOp.R.rawValue))}

    public static let UDLR = MenuOp([.U,.D,.L,.R]).rawValue
    public static let UDLRVH = MenuOp([.U,.D,.L,.R,.V,.H]).rawValue

    public var corner: MenuCorner {
        
        switch self.rawValue & MenuOp.UDLR {
        case (_U + _R) : return .upRight
        case (_U + _L) : return .upLeft
        case (_D + _R) : return .downRight
        case (_D + _L) : return .downLeft
        default        : return .none
        }
    }
    public var cornerAxis: MenuCornerAxis {

        switch self.rawValue & MenuOp.UDLRVH {
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

    public static let charOp: [Character: MenuOp] = [
        "U": .U  , "D": .D  ,
        "L": .L  , "R": .R  ,
        "H": .H  , "V": .V  ,
        "0": .Z0 , "1": .Z1 ,
    ]

    public var key: String {
        MenuOp.charOp.compactMap { (char, op) in
            self.contains(op) ? String(char) : nil
        }.joined()
    }
    public var description: String {
        let mapping: [(MenuOp, String)] = [
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
            guard let op = MenuOp.charOp[char], self.contains(op) else {
                return false
            }
        }
        return true
    }

    static func flipUpperLower(_ oldOp: Int) -> Int {

        return oldOp ^ MenuOp([.U, .D]).rawValue
    }

    var hAlign: HorizontalAlignment { self.left ? .leading : .trailing }
    var vAlign: VerticalAlignment   { self.up ? .top : .bottom }
    var alignment: Alignment { Alignment(horizontal: hAlign, vertical: vAlign) }

}

