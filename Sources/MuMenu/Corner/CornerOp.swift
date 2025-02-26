//  created by musesum on 11/4/21.

import SwiftUI

public struct CornerOp: OptionSet {

    public let rawValue: Int
    static func flipUpperLower(_ oldOp: Int) -> Int {
        return oldOp ^ CornerOp([.upper,.lower]).rawValue
    }

    var hAlign: HorizontalAlignment { self.left ? .leading : .trailing }
    var vAlign: VerticalAlignment   { self.upper ? .top : .bottom }
    var alignment: Alignment { Alignment(horizontal: hAlign, vertical: vAlign) }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let upper = CornerOp(rawValue: 1 << 0) // 1
    public static let lower = CornerOp(rawValue: 1 << 1) // 2
    public static let left  = CornerOp(rawValue: 1 << 2) // 4
    public static let right = CornerOp(rawValue: 1 << 3) // 8

    var upper : Bool { contains(.upper)}
    var lower : Bool { contains(.lower)}
    var left  : Bool { contains(.left )}
    var right : Bool { contains(.right)}

    var side  : Int { rawValue & CornerOp([.left,.right]).rawValue }

    static public var description: [(Self, String)] = [
        (.upper,  "upper"),
        (.lower,  "lower"),
        (.left,   "left"),
        (.right,  "right"),
    ]

    public var description: String {
        let result: [String] = Self.description.filter { contains($0.0) }.map { $0.1 }
        let printable = result.joined(separator: ", ")
        return "\(printable)"
    }

    public func str() -> String {
        switch self {
            case [.lower, .right]: return "SE" // south east
            case [.lower, .left ]: return "SW" // south west
            case [.upper, .right]: return "NE" // north east
            case [.upper, .left ]: return "NW" // north west

                // reserved for later middling roots
            case [.upper]: return "N"
            case [.right]: return "E"
            case [.lower]: return "S"
            case [.left ]: return "W"
            default:       return "??"
        }
    }
    public func indicator () -> String {
        switch self {
            case [.lower, .right]: return "◢"
            case [.lower, .left ]: return "◣"
            case [.upper, .right]: return "◥"
            case [.upper, .left ]: return "◤"

                // reserved for later middling roots
            case [.upper]: return "▲"
            case [.right]: return "▶︎"
            case [.lower]: return "▼"
            case [.left ]: return "◀︎"
            default:       return "??"
        }
    }
}

