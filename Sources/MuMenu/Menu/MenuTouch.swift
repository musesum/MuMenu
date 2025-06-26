//  created by musesum on 9/26/22

import UIKit
import MuFlo // double buffer
import MuPeers

nonisolated(unsafe) public var MenuTypeCornerVm = [Int: CornerVm]()

public class MenuTouch {

    nonisolated(unsafe) static var menuKey = [Int: MenuTouch]()
    private let buffer = CircleBuffer<MenuItem>(capacity: 3, internalLoop: true)
    private let isRemote: Bool

    public init(isRemote: Bool) {
        
        self.isRemote = isRemote
        buffer.delegate = self
    }
}

extension MenuTouch: CircleBufferDelegate {

    public typealias Item = MenuItem

    public func flushItem<Item>(_ item: Item, _ type: BufType) -> BufState {
        let item = item as! MenuItem

        if isRemote {

            switch item.element {
                case .node, .leaf:
                    item.cornerVm?.gotoMenuItem(item)
                case .root:
                    if let root = item.item as? MenuRootItem {
                        for tree in root.trees {
                            tree.showTree(isRemote)
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
            menu.buffer.addItem(item, bufType: .remoteBuf)
        } else {
            let touchMenu = MenuTouch(isRemote: true)
            menuKey[item.key] = touchMenu
            touchMenu.buffer.addItem(item, bufType: .remoteBuf)
        }
    }
}
