//  created by musesum on 12/13/22.

import Foundation
import MuFlo
import UIKit

@MainActor
extension CornerVm {

    /// called by UIKit to see if UITouchBegin hits a menu.
    /// If not, it will not call touch
    public func hitTest(_ touchNow: CGPoint) -> NodeVm? {
        if let logoNodeVm, logoNodeVm.contains(touchNow) {
            return logoNodeVm // hits the root (home) node icon
        } else if let rootVm, let nodeVm = rootVm.hitTest(touchNow) {
            return nodeVm // hits one of the shown branches
        }
        return nil // does NOT hit menu
    }

    public func gotoMenuItem(_ item: MenuItem) {
        switch item.item {
        case .node(let nodeItem):
            _ = nodeItem.treeVm?.gotoNodeItem(nodeItem)

        case .leaf(let leafItem):
            if let leafVm = leafItem.treeVm?.gotoLeafItem(leafItem) {
                leafVm.remoteThumb(leafItem.leafThumb, Visitor(0, .remote))
            }

        case .touch(let touchItem):
            updateRemoteTouch(touchItem, item.phase)

        default:
            break
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
