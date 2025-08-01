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
    case VW, // vertical westward
         VE, // vertical eastward
         HN, // horizontal northward
         HS  // horizontal southward
}

public struct MenuType: OptionSet, Codable, Hashable, Sendable {
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

    public static let N  = MenuType(rawValue: 1 <<  0) // north
    public static let S  = MenuType(rawValue: 1 <<  1) // south
    public static let E  = MenuType(rawValue: 1 <<  2) // east
    public static let W  = MenuType(rawValue: 1 <<  3) // west
    public static let H  = MenuType(rawValue: 1 <<  4) // hori
    public static let V  = MenuType(rawValue: 1 <<  5) // vert
    public static let Z0 = MenuType(rawValue: 1 <<  6) // near
    public static let Z1 = MenuType(rawValue: 1 <<  7) // far
    public static let Q  = MenuType(rawValue: 1 <<  8) // quest
    public static let L  = MenuType(rawValue: 1 <<  9) // left hand
    public static let R  = MenuType(rawValue: 1 << 10) // right Hand

    public var north    : Bool { self.contains(.N ) }
    public var south    : Bool { self.contains(.S ) }
    public var east     : Bool { self.contains(.E ) }
    public var west     : Bool { self.contains(.W ) }
    public var near     : Bool { self.contains(.Z0) }
    public var far      : Bool { self.contains(.Z1) }
    public var horizon  : Bool { self.contains(.H ) }
    public var vertical : Bool { self.contains(.V ) }
    public var quest    : Bool { self.contains(.Q ) }
    public var left     : Bool { self.contains(.L ) }
    public var right    : Bool { self.contains(.R ) }

    public var chiral: MenuType {
        self.intersection([.E,.W])
    }

    public var corner: MenuCorner {
        switch self.intersection([.N,.S,.E,.W]){
        case [.N,.E] : return .NE
        case [.N,.W] : return .NW
        case [.S,.E] : return .SE
        case [.S,.W] : return .SW
        default      : return .none
        }
    }

    public var cornerAxis: MenuCornerAxis {
        switch self.intersection([.N,.S,.E,.W,.V,.H]) {
        case [.N,.W,.V] : return .NWV
        case [.N,.W,.H] : return .NWH
        case [.N,.E,.V] : return .NEV
        case [.N,.E,.H] : return .NEH
        case [.S,.W,.V] : return .SWV
        case [.S,.W,.H] : return .SWH
        case [.S,.E,.V] : return .SEV
        case [.S,.E,.H] : return .SEH
        default         : return .none
        }
    }
    public var icon: String {
        var str  = ""
        switch self.intersection([.N,.S,.E,.W]) {
        case [.N,.E] : str += "◥"
        case [.N,.W] : str += "◤"
        case [.S,.E] : str += "◢"
        case [.S,.W] : str += "◣"
        default      : str += "⬜︎"
        }
        switch self.intersection([.V,.H]) {
        case [.V] : str += "❚"
        case [.H] : str += "▬"
        default   : break
        }
        switch self.intersection([.L,.R]){
        case [.L]    : str += "←⏺"
        case [.R]    : str += "⏺→"
        case [.L,.R] : str += "←⏺→"
        default      : break
        }
        switch self.intersection([.Q]) {
        case [.Q]       : str += "Q"
        default         : break
        }
        return str
    }
    public var progression: MenuProgression {
        return (vertical
                ? (west ? .VW : .VE)
                : (north ? .HN : .HS))
    }
    public static let charOp: [Character: MenuType] = [
        "N": .N  , "S": .S  ,
        "E": .E  , "W": .W  ,
        "H": .H  , "V": .V  ,
        "0": .Z0 , "1": .Z1 ,
        "L": .L  , "R": .R  ,
        "Q": .Q
    ]

    public var key: String {
        let order = "NSEWHV01"
        return order.filter { char in
            if let op = MenuType.charOp[char] {
                return self.contains(op)
            }
            return false
        }
    }
    public var description: String {
        let mapping: [(MenuType, String)] = [
            (.N  , "north"  ), (.S  , "south"    ),
            (.W  , "west"   ), (.E  , "east"     ),
            (.H  , "horizon"), (.V  , "vertical" ),
            (.Z0 , "near"   ), (.Z1 , "far"      ),
            (.L  , "left"   ), (.R  , "right"    ),
            (.Q  , "quest"  )
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

    static func flipNS(_ oldOp: Int) -> Int {

        return oldOp ^ MenuType([.N,.S]).rawValue
    }

    var hAlign: HorizontalAlignment { self.west ? .leading : .trailing }
    var vAlign: VerticalAlignment   { self.north ? .top : .bottom }
    var alignment: Alignment { Alignment(horizontal: hAlign, vertical: vAlign) }

}
