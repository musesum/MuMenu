//  created by musesum on 12/21/21.

import SwiftUI

public enum NodeType: String, Codable {
    case none   // no defined type
    case node   // either icon or text
    case val    // value control
    case xy     // 2-axis XY control
    case xyz    // 3-axis XYZ control
    case xyzw   // 4-axis XYZW control (w slider on bottom, aligned with x)
    case vf     // v/f sliders in y/w slots, center scope (band-pass + PCM)
    case tog    // toggle on/off
    case tap    // tapping
    case seg    // segment control
    case peer   // join a peer network
    case arch   // list of archives
    case hand   // hand pose control
    case search // voice search node
    case graph  // d3 force-directed view of the flo graph
    case code   // annotated shader source editor bound to a flo embed
    case midi   // 88-note grid lit by midi input or mic FFT
    case sequencer // tape piano roll with transport + loop window

    public var description: String {
        switch self {
        case .none   : return "none"
        case .node   : return "node"
        case .val    : return "val"
        case .xy     : return "xy"
        case .xyz    : return "xyz"
        case .xyzw   : return "xyzw"
        case .vf     : return "vf"
        case .tog    : return "tog"
        case .tap    : return "tap"
        case .seg    : return "seg"
        case .peer   : return "peer"
        case .arch   : return "arch"
        case .hand   : return "hand"
        case .search : return "search"
        case .graph  : return "graph"
        case .code   : return "code"
        case .midi   : return "midi"
        case .sequencer : return "sequencer"
        }
    }

    init(_ name: String) {

        switch name {
        case "none"   : self = .none
        case "node"   : self = .node
        case "val"    : self = .val
        case "xy"     : self = .xy
        case "xyz"    : self = .xyz
        case "xyzw"   : self = .xyzw
        case "vf"     : self = .vf
        case "tog"    : self = .tog
        case "tap"    : self = .tap
        case "seg"    : self = .seg
        case "peer"   : self = .peer
        case "arch"   : self = .arch
        case "search" : self = .search
        case "graph"  : self = .graph
        case "code"   : self = .code
        case "midi"   : self = .midi
        case "sequencer" : self = .sequencer
        default       : self = .none
        }
    }

    /// control will create separate child leaf
    public var isControl: Bool {
        switch self {
        case .node, .none, .tog, .tap: return false
        case .val, .seg, .xy, .xyz, .xyzw, .vf, .peer, .hand, .arch, .search, .graph, .code, .midi, .sequencer: return true
        }
    }
}
