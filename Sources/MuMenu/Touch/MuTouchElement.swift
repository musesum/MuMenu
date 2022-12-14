//  Created by warren on 11/24/21.

import Foundation

enum MuTouchElement: String  {
    
    case none   /// starting point before touching
    case root   /// starting node hosting 1 or more trees
    case branch /// branches expanded for one tree
    case trunks /// only first branch of multiple trees
    case node   /// hovering over a specific node
    case shift  /// shifting branches by dragging header for leaf
    case edit   /// editing area inside a leaf
    case space  /// hovering over canvas while on menu
    case edge   /// unsafe area to expand tree branches
    
    public var symbol: String {
        switch self {
            case .none   : return "ΓΈ"
            case .root   : return "β"
            case .trunks : return "α"
            case .branch : return "π·"
            case .node   : return "β"
            case .shift  : return "βͺ"
            case .edit   : return "β"
            case .space  : return "β"
            case .edge   : return "β«Ό"
        }
    }
    public var description: String {
        switch self {
            case .none   : return "none"
            case .root   : return "root"
            case .trunks : return "trunks"
            case .branch : return "branch"
            case .node   : return "node"
            case .shift  : return "shift"
            case .edit   : return "edit"
            case .space  : return "space"
            case .edge   : return "edge"
        }
    }
    static public func symbols(_ set: Set<MuTouchElement>) -> String {
        var result = "γ"
        for item in set {
            result += item.symbol
        }
        result += "γ"
        return result
    }
}

