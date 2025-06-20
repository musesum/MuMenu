//  created by musesum on 12/21/21.

import SwiftUI

public enum NodeType: String, Codable {
    case none   // no defined type
    case node   // either icon or text
    case val    // value control
    case xy     // 2-axis XY control
    case xyz    // 3-azis XYZ control
    case tog    // toggle on/off
    case seg    // segment control
    case peer   // join a peer network
    case arch   // list of archives
    case hand   // hand pose control
    case search // voice search node

    public var description: String {
        switch self {
        case .none   : return "none"
        case .node   : return "node"
        case .val    : return "val"
        case .xy     : return "xy"
        case .xyz    : return "xyz"
        case .tog    : return "tog"
        case .seg    : return "seg"
        case .peer   : return "peer"
        case .arch   : return "arch"
        case .hand   : return "hand"
        case .search : return "search"
        }
    }

    public var name: String {
        return description
    }
    public func nodeType(for key: String) -> NodeType? {
        return NodeType(rawValue: key)
    }

    init(_ name: String) {

        switch name {
        case "none"   : self = .none
        case "node"   : self = .node
        case "val"    : self = .val
        case "xy"     : self = .xy
        case "xyz"    : self = .xyz
        case "tog"    : self = .tog
        case "seg"    : self = .seg
        case "peer"   : self = .peer
        case "arch"   : self = .arch
        case "search" : self = .search
        default       : self = .none
        }
    }

    /// control will create separate child leaf
    public var isControl: Bool {
        switch self {
        case .node, .none, .tog: return false
        case .val, .seg, .xy, .xyz, .peer, .hand, .arch, .search: return true
        }
    }
}
