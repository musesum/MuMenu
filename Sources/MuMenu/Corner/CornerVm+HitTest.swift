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
                if !treeVm.showTree.state.hidden,
                    treeVm.treeBoundsPad.contains(touchNow) {
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
}
