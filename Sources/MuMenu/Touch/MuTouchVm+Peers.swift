//  Created by warren on 12/13/22.

import Foundation
import Par // Visitor
import UIKit

extension MuTouchVm {

    /// called by UIKit to see if UITouchBegin hits a menu.
    /// If not, it will not call touch
    public func hitTest(_ touchNow: CGPoint) ->  MuNodeVm? {
        if let rootNodeVm, rootNodeVm.containsPoint(touchNow) {
            return rootNodeVm // hits the root (home) node icon
        } else if let rootVm, let nodeVm = rootVm.hitTest(touchNow) {
            return nodeVm // hits one of the shown branches
        }
        return nil // does NOT hit menu
    }

    public func gotoNodeItem(_ item: MenuItem) {
        if let node = item.node,
           let foundNodeVm = node.treeVm?.followHashPath(node) {

            if let leafVm = foundNodeVm as? MuLeafVm {
                updateRemoteLeafVm(leafVm, node)
            } else {
                updateRemoteNodeVm(foundNodeVm, item)
            }
        }
    }

    func updateRemoteLeafVm(_ leafVm: MuLeafVm,
                            _ nodeItem: MenuNodeItem) {
        
        DispatchQueue.main.async {

            if let leafProto = leafVm.leafProto {
                log("remoteLeaf", [nodeItem.thumb])
                leafProto.updateLeaf(nodeItem.thumb, Visitor(fromRemote: true))
            }
        }
    }
    /// called either by SwiftUI MenuView DragGesture or UIKIt touchesUpdate
    public func updateRemoteNodeVm(_ nodeVm: MuNodeVm,
                                   _ menuItem: MenuItem) {

        DispatchQueue.main.async {

            let xy = nodeVm.center
            let phase = UITouch.Phase(rawValue: menuItem.phase)
            log("remoteNode", [xy, "phase: ", menuItem.phase])
            switch phase {
                case .began: self.begin(xy, fromRemote: true)
                case .moved: self.moved(xy, fromRemote: true)
                default:     self.ended(xy, fromRemote: true)
            }
            self.alignCursor(xy)
        }
    }
}
