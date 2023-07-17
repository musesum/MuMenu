//  Created by warren on 12/13/22.

import Foundation
import MuVisit
import UIKit

extension MuTouchVm {

    /// called by UIKit to see if UITouchBegin hits a menu.
    /// If not, it will not call touch
    public func hitTest(_ touchNow: CGPoint) ->  MuNodeVm? {
        if let rootNodeVm, rootNodeVm.containsPoint(touchNow) {
            return rootNodeVm // hits the root (home) node icon
        } else if let rootVm, let nodeVm = rootVm.hitTest(touchNow) {
            return nodeVm // hits one of the shown branches
        }
        return nil // does NOT hit menu
    }

    public func gotoMenuItem(_ item: MenuItem) {
        switch item.type {
            case .node:

                if let nodeItem = item.item as? MenuNodeItem {

                    _  = nodeItem.treeVm?.gotoNodeItem(nodeItem)
                }

            case .leaf:

                if let leafItem = item.item as? MenuLeafItem,
                   let leafVm = leafItem.treeVm?.gotoLeafItem(leafItem),
                   let leafProto = leafVm.leafProto {
                    
                    print("􀤆", terminator: "")
                    DispatchQueue.main.async {
                        leafProto.updateFromThumbs(leafItem.thumbs, Visitor(.remote))
                    }
                }
            case .touch:

                if let touchItem = item.item as? MenuTouchItem {

                    updateRemoteTouch(touchItem, item.phase)
                }

            default: break
        }
    }

    /// current not called, useful for shared screen where teacher controls the students root cursor
    public func updateRemoteTouch(_ touchItem: MenuTouchItem,
                                  _ phase: Int) {

        DispatchQueue.main.async {

            let xy = touchItem.cgPoint

            switch phase.uiPhase() {
                case .began: self.begin(xy, fromRemote: true)
                case .moved: self.moved(xy, fromRemote: true)
                default:     self.ended(xy, fromRemote: true)
            }
            self.alignCursor(xy)
        }
    }
}
