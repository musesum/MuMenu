//  created by musesum on 9/26/22

import UIKit
import MuFlo // double buffer
import MuPeers

nonisolated(unsafe) public var MenuTypeCornerVm = [Int: CornerVm]()

@MainActor
public class MenuTouch {

    nonisolated(unsafe) static var menuKey = [Int: MenuTouch]()
    private let buffer: CircleBuffer<MenuItem>
    private let isRemote: Bool

    public init(isRemote: Bool) {
        
        self.isRemote = isRemote
        self.buffer = CircleBuffer<MenuItem>()
        buffer.delegate = self
    }
}

extension MenuTouch: CircleBufferDelegate {

    public typealias Item = MenuItem

    public func flushItem<Item>(_ item: Item, _ from: DataFrom) -> BufState {
        let item = item as! MenuItem

        if isRemote {

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

                    leafVm.remoteThumb(item, Visitor(0, .remote))
                }
            case .trees:
                if let trees = item.item as? MenuTreesItem {
                    for treeItem in trees.treeItems {
                        treeItem.remoteTree()
                    }
                }
           
            default: break
            }
        } else if let touch = item.item as? MenuTouchItem {
            item.cornerVm?.updateTouchXY(touch.cgPoint, item.phase)
        }
        return .nextBuf
    }
}
extension MenuTouch {

    public static func remoteItem(_ item: MenuItem) {
        if let menu = menuKey[item.key] {
            menu.buffer.addItem(item, from: .remote)
        } else {
            let touchMenu = MenuTouch(isRemote: true)
            menuKey[item.key] = touchMenu
            touchMenu.buffer.addItem(item, from: .remote)
        }
    }
}
