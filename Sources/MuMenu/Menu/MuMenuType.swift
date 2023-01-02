//  Created by warren on 12/21/21.

import SwiftUI

public enum MuMenuType: String {
    case none // no defined thpe
    case node // either icon or text
    case val  // value control
    case vxy  // value XY control
    case tog  // toggle on/off
    case tap  // tap a button
    case seg  // segment control
    case peer // join a peer network
    case tree // status of menu tree

    public var description: String {
        switch self {
            case .none : return "none"
            case .node : return "node"
            case .val  : return "val"
            case .vxy  : return "vxy"
            case .tog  : return "tog"
            case .seg  : return "seg"
            case .tap  : return "tap"
            case .peer : return "peer"
            case .tree : return "tree"
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
            case .vxy  : return "᛭⃣"
            case .tog  : return "◧⃝"
            case .seg  : return "◔⃝"
            case .tap  : return "◉⃝"
            case .peer : return "⇵⃝"
            case .tree : return "ᛘ⃝"
        }
    }


    init(_ name: String) {

        switch name {
            case "none" : self = .none
            case "node" : self = .node
            case "val"  : self = .val
            case "vxy"  : self = .vxy
            case "tog"  : self = .tog
            case "seg"  : self = .seg
            case "tap"  : self = .tap
            case "peer" : self = .peer
            case "tree" : self = .tree
            default     : self = .none
        }
    }
    public var isLeaf: Bool {
        switch self {
            case .node, .none: return false
            default: return true
        }
    }

}

public let MuNodeLeafNames = ["val", "vxy", "tog", "seg", "tap", "peer", "x", "y"]
public let MuNodeLeaves = Set<String>(["val", "vxy", "tog", "seg", "tap", "peer"])
