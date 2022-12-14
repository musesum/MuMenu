//  Created by warren on 11/4/21.

import Foundation

public struct MuCorner: OptionSet {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let upper = MuCorner(rawValue: 1 << 0) // 1
    public static let lower = MuCorner(rawValue: 1 << 1) // 2
    public static let left  = MuCorner(rawValue: 1 << 2) // 4
    public static let right = MuCorner(rawValue: 1 << 3) // 8

    static public var description: [(Self, String)] = [
        (.upper , "upper"),
        (.lower , "lower"),
        (.left  , "left"),
        (.right , "right"),
    ]

    public var description: String {
        let result: [String] = Self.description.filter { contains($0.0) }.map { $0.1 }
        let printable = result.joined(separator: ", ")
        return "\(printable)"
    }

    public func str() -> String {
        switch self {
            case [.lower, .right]: return "SE"
            case [.lower, .left ]: return "SW"
            case [.upper, .right]: return "NE"
            case [.upper, .left ]: return "NW"

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

