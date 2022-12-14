// Created by warren on 10/17/21.

import SwiftUI

/// shared between 1 or more MuNodeVm
public class MuCornerNode: MuNode {
    
    public init(_ name: String,
                type: MuNodeType = .node,
                parent: MuNode? = nil,
                children: [MuCornerNode]? = nil) {

        let icon = MuIcon(.cursor, named: Layout.hoverRing)
        super.init(name: name, icon: icon)
        
        if let children {
            for child in children {
                self.addChild(child)
            }
        }
    }

    func setName(from corner: MuCorner) {
        switch corner {
            case [.lower, .right]: title = "◢"
            case [.lower, .left ]: title = "◣"
            case [.upper, .right]: title = "◥"
            case [.upper, .left ]: title = "◤"

                // reserved for later middling roots
            case [.upper]: title = "▲"
            case [.right]: title = "▶︎"
            case [.lower]: title = "▼"
            case [.left ]: title = "◀︎"
            default:       break
        }
    }

    func addChild(_ child: MuNode) {
        children.append(child)
    }
    
}
