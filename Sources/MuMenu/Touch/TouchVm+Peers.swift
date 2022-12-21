//  Created by warren on 12/13/22.

import Foundation
import Par // Visitor
extension MuTouchVm {

    /// called by UIKit to see if UITouchBegin hits a menu.
    /// If not, it will not call touch
    public func hitTest(_ touchNow: CGPoint) -> (MuCorner, MuNodeVm)? {
        guard let corner = rootVm?.corner else {
            print("⁉️ hitTest rootVm?.corner == nil")
            return nil
        }
        if let rootNodeVm, rootNodeVm.contains(touchNow) {
            return (corner,rootNodeVm) // hits the root (home) node icon
        } else if let rootVm, let nodeVm = rootVm.hitTest(touchNow) {
            return (corner,nodeVm) // hits one of the shown branches
        }
        return nil // does NOT hit menu
    }

    public func gotoRemoteItem(_ menuItem: TouchMenuItem) {

        guard let rootVm else { return }
        let hashPath = menuItem.hashPath
        for treeVm in rootVm.treeVms {
            if let foundNodeVm = treeVm.followHashPath(hashPath) {
                if let leafVm = foundNodeVm as? MuLeafVm {
                    var thumb = [Double]()
                    for point in menuItem.point {
                        thumb.append(Double(point))
                    }
                    DispatchQueue.main.async {
                        if let leafProto = leafVm.leafProto {
                            leafProto.updateLeaf(thumb, Visitor().fromRemote())
                        }
                    }
                } else {
                    updateNodeVm(foundNodeVm, menuItem)
                }
                break
            }
        }
    }
}
