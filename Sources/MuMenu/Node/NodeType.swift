//  created by musesum on 12/21/21.

import SwiftUI

public enum NodeType: String {
    case none // no defined type
    case node // either icon or text
    case val  // value control
    case xy   // value XY control
    case xyz  // value XYX\Z control
    case tog  // toggle on/off
    case tap  // tap a button
    case seg  // segment control
    case peer // join a peer network
    case hand // hand pose control

    public var description: String {
        switch self {
        case .none : return "none"
        case .node : return "node"
        case .val  : return "val"
        case .xy   : return "xy"
        case .xyz  : return "xyz"
        case .tog  : return "tog"
        case .seg  : return "seg"
        case .tap  : return "tap"
        case .peer : return "peer"
        case .hand : return "hand"
        }
    }
    public var name: String {
        return description
    }
    public var icon: String {
        switch self {
        case .none : return " ⃝"
        case .node : return "●⃝"
        case .val  : return "≣⃝"
        case .xy   : return "᛭⃣"
        case .xyz  : return "∛⃣"
        case .tog  : return "◧⃝"
        case .seg  : return "◔⃝"
        case .tap  : return "◉⃝"
        case .peer : return "⇵⃝"
        case .hand : return "🤚"
        }
    }

    init(_ name: String) {

        switch name {
        case "none" : self = .none
        case "node" : self = .node
        case "val"  : self = .val
        case "xy"   : self = .xy
        case "xyz"  : self = .xyz
        case "tog"  : self = .tog
        case "seg"  : self = .seg
        case "tap"  : self = .tap
        case "peer" : self = .peer
        case "hand" : self = .hand
        default     : self = .none
        }
    }
    public var isLeaf: Bool {
        switch self {
            case .node, .none: return false
            default: return true
        }
    }
    public var isControl: Bool {
        switch self {
            case .node, .none, .tap, .tog: return false
            default: return true
        }
    }
    public var isTog: Bool {
        switch self {
            case .tog, .tap: return true
            default: return false
        }
    }
}
