//  Created by warren on 12/13/22.

import Foundation
import Par // Visitor

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

    public func gotoRemoteItem(_ menuItem: TouchMenuItem) {

        guard let rootVm else { return }
        let treePath = menuItem.treePath
        let treeNow = menuItem.treeNow
        for treeVm in rootVm.treeVms {
            if let foundNodeVm = treeVm.followHashPath(treePath, treeNow) {
                if let leafVm = foundNodeVm as? MuLeafVm {
                    updateLeafVm(leafVm, menuItem)
                } else {
                    updateNodeVm(foundNodeVm, menuItem)
                }
                break
            }
        }
    }
    func updateLeafVm(_ leafVm: MuLeafVm,
                      _ menuItem: TouchMenuItem) {
        DispatchQueue.main.async {
            if let leafProto = leafVm.leafProto {
                leafProto.updateLeaf(menuItem.thumb, Visitor().fromRemote())
            }

        }
    }
}
