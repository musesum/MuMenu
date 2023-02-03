//  Created by warren on 11/24/21.

import Foundation

// touch option
enum MuTouchOp  {
    
    case none   /// starting point before touching
    case root   /// starting node hosting 1 or more trees
    case branch /// branches expanded for one tree
    case trunks /// only first branch of multiple trees
    case node   /// hovering over a specific node
    case canopy /// shift tree from whole canopy
    case shift  /// shifting branches by dragging header for leaf
    case edit   /// editing area inside a leaf
    case space  /// hovering over canvas while on menu
    
    public var symbol: String {
        switch self {
            case .none   : return "ø"
            case .root   : return "√"
            case .trunks : return "ᛘ"
            case .branch : return "𐂷"
            case .node   : return "ⓝ"
            case .canopy : return "􁝯"
            case .shift  : return "􀄭"
            case .edit   : return "􀤹"
            case .space  : return "􁁺"
        }
    }
    public var description: String {
        switch self {
            case .none   : return "none"
            case .root   : return "root"
            case .trunks : return "trunks"
            case .branch : return "branch"
            case .node   : return "node"
            case .canopy : return "canopy"
            case .shift  : return "shift"
            case .edit   : return "edit"
            case .space  : return "space"
        }
    }

    var none   : Bool { self == .none   }
    var root   : Bool { self == .root   }
    var branch : Bool { self == .branch }
    var trunks : Bool { self == .trunks }
    var node   : Bool { self == .node   }
    var canopy : Bool { self == .canopy }
    var shift  : Bool { self == .shift  }
    var edit   : Bool { self == .edit   }
    var space  : Bool { self == .space  }

    static public func symbols(_ set: Set<MuTouchOp>) -> String {
        var result = "〈"
        for item in set {
            result += item.symbol
        }
        result += "〉"
        return result
    }
    func isIn(_ elements: [MuTouchOp]) -> Bool {
        for element in elements {
            if element == self {
                return true
            }
        }
        return false
    }
}

