//  created by musesum on 12/13/22.

import Foundation
import MuFlo
import UIKit

extension CornerVm {

    /// called by UIKit to see if UITouchBegin hits a menu.
    /// If not, it will not call touch
    public func hitTest(_ touchNow: CGPoint) ->  NodeVm? {
        if let logoNodeVm, logoNodeVm.contains(touchNow) {
            return logoNodeVm // hits the root (home) node icon
        } else {
            for treeVm in rootVm?.treeVms ?? [] {
                if treeVm.treeBoundsPad.contains(touchNow) {
                    for branchVm in treeVm.branchVms {
                        if branchVm.show, branchVm.contains(touchNow) {
                            if let nodeVm =  branchVm.nearestNode(touchNow) {
                                return nodeVm
                            }
                        }
                    }
                    if let nodeVm = treeVm.branchSpotVm?.nodeSpotVm {
                        return nodeVm
                    }
                }
            }
        }
        return nil // does NOT hit menu
    }

    public func gotoMenuItem(_ item: MenuItem) {
        
        switch item.element {
            case .node:

                if let item = item.item as? MenuNodeItem,
                   let treeVm = item.treeVm {
                    _ = treeVm.followWordPath(item.wordPath, item.wordNow)
                }

            case .leaf:

                if let item = item.item as? MenuLeafItem,
                   let treeVm = item.treeVm,
                   let nodeVm = treeVm.followWordPath(item.wordPath, item.wordNow),
                   let leafVm = nodeVm as? LeafVm {

                    DispatchQueue.main.async {
                        leafVm.remoteThumb(item, Visitor(0, .remote))
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

        // DispatchQueue.main.async {

            let xy = touchItem.cgPoint

            switch phase.uiPhase() {
                case .began: self.begin(xy, fromRemote: true)
                case .moved: self.moved(xy, fromRemote: true)
                default:     self.ended(xy, fromRemote: true)
            }
            self.alignCursor(xy)
        //}
    }
}
