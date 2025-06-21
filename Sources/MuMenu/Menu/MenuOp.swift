// created by musesum on 6/14/25
import SwiftUI

public enum MenuCorner {
    case none, NW, NE, SW, SE
    var icon: String {
        switch self {
        case .none : "⬜︎"
        case .NW   : "◤"
        case .NE   : "◥"
        case .SW   : "◣"
        case .SE   : "◢"
        }
    }
}

public enum MenuCornerAxis: String {
    case none, NWV, NWH, NEV, NEH, SWV, SWH, SEV, SEH
}

public enum MenuProgression {
    case VW, // vertical leftward
         VE, // vertical rightward
         HN, // horiontal upward
         HS  // horizontal downward
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
    public static let N  = MenuType(rawValue: 1 << 0) // north
    public static let S  = MenuType(rawValue: 1 << 1) // south
    public static let E  = MenuType(rawValue: 1 << 2) // east
    public static let W  = MenuType(rawValue: 1 << 3) // west
    public static let H  = MenuType(rawValue: 1 << 4) // hori
    public static let V  = MenuType(rawValue: 1 << 5) // vert
    public static let _0 = MenuType(rawValue: 1 << 6) // near
    public static let _1 = MenuType(rawValue: 1 << 7) // far
    public static let NW = MenuType("NW")
    public static let NE = MenuType("NE")
    public static let SW = MenuType("SW")
    public static let SE = MenuType("SE")

    public static let NWV = MenuType("NWV")
    public static let NWH = MenuType("NWH")
    public static let NEV = MenuType("NEV")
    public static let NEH = MenuType("NEH")
    public static let SWV = MenuType("SWV")
    public static let SWH = MenuType("SWH")
    public static let SEV = MenuType("SEV")
    public static let SEH = MenuType("SEH")

    public var north    : Bool { self.contains(.N ) }
    public var south    : Bool { self.contains(.S ) }
    public var east     : Bool { self.contains(.E ) }
    public var west     : Bool { self.contains(.W ) }
    public var near     : Bool { self.contains(._0) }
    public var far      : Bool { self.contains(._1) }
    public var horizon  : Bool { self.contains(.H ) }
    public var vertical : Bool { self.contains(.V ) }

    public var chiral: MenuType { MenuType(rawValue: self.rawValue & _EW) }

    let _N  =  MenuType.N .rawValue
    let _S  =  MenuType.S .rawValue
    let _W  =  MenuType.W .rawValue
    let _E  =  MenuType.E .rawValue
    let _H  =  MenuType.H .rawValue
    let _V  =  MenuType.V .rawValue
    let _NS = MenuType([.N,.S]).rawValue
    let _EW = MenuType([.E,.W]).rawValue
    let _NSEW = MenuType([.N,.S,.E,.W]).rawValue
    let _NSEWVH = MenuType([.N,.S,.E,.W,.V,.H]).rawValue

    public var corner: MenuCorner {

        switch self.rawValue & _NSEW {
        case (_N|_E) : return .NE
        case (_N|_W) : return .NW
        case (_S|_E) : return .SE
        case (_S|_W) : return .SW
        default      : return .none
        }
    }

    public var cornerAxis: MenuCornerAxis {

        switch self.rawValue & _NSEWVH {
        case (_N|_W|_V) : return .NWV
        case (_N|_W|_H) : return .NWH
        case (_N|_E|_V) : return .NEV
        case (_N|_E|_H) : return .NEH
        case (_S|_W|_V) : return .SWV
        case (_S|_W|_H) : return .SWH
        case (_S|_E|_V) : return .SEV
        case (_S|_E|_H) : return .SEH
        default             : return .none
        }
    }
    public var icon: String {
        switch self.rawValue & _NSEWVH {
        case (_N|_W|_V) : return "◤❚"
        case (_N|_W|_H) : return "◤▬"
        case (_N|_E|_V) : return "❚◥"
        case (_N|_E|_H) : return "▬◥"
        case (_S|_W|_V) : return "◣❚"
        case (_S|_W|_H) : return "◣▬"
        case (_S|_E|_V) : return "❚◢"
        case (_S|_E|_H) : return "▬◢"
        default         : return "⬜︎"
        }
    }
    public var progression: MenuProgression {
        return (vertical
                ? (west ? .VW : .VE)
                : (north ? .HN : .HS))
    }
    public static let charOp: [Character: MenuType] = [
        "N": .N  , "S": .S  ,
        "W": .W  , "E": .E  ,
        "H": .H  , "V": .V  ,
        "0": ._0 , "1": ._1 ,
    ]

    public var key: String {
        MenuType.charOp.compactMap { (char, op) in
            self.contains(op) ? String(char) : nil
        }.joined()
    }
    public var description: String {
        let mapping: [(MenuType, String)] = [
            (.N  , "north"  ), (.S  , "south"    ),
            (.W  , "west"   ), (.E  , "east"     ),
            (.H  , "horizon"), (.V  , "vertical" ),
            (._0 , "near"   ), (._1 , "far"      )
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

        return oldOp ^ MenuType([.N, .S]).rawValue
    }

    var hAlign: HorizontalAlignment { self.west ? .leading : .trailing }
    var vAlign: VerticalAlignment   { self.north ? .top : .bottom }
    var alignment: Alignment { Alignment(horizontal: hAlign, vertical: vAlign) }

}

