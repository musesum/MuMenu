//  created by musesum on 9/26/22

import UIKit
import MuFlo // double buffer
import MuPeer

public var CornerTouchVm = [Int: TouchVm]()

public class MenuTouch {

    static var menuKey = [Int: MenuTouch]()
    private let buffer = DoubleBuffer<MenuItem>(internalLoop: true)
    private let isRemote: Bool

    public init(isRemote: Bool) {
        
        self.isRemote = isRemote
        buffer.delegate = self
    }

}

extension MenuTouch: DoubleBufferDelegate {

    public typealias Item = MenuItem

    public func flushItem<Item>(_ item: Item) -> Bool {
        let item = item as! MenuItem

        if isRemote {
            switch item.type {
                case .node, .leaf:
                    item.touchVm?.gotoMenuItem(item)
                case .root:
                    if let root = item.item as? MenuRootItem {
                        for tree in root.trees {
                            tree.showTree(isRemote)
                        }
                    }
                default: break
            }

        } else if let touch = item.item as? MenuTouchItem {
            item.touchVm?.updateTouchXY(touch.cgPoint, item.phase)
        }
        return false // never invalidate internal timer
    }
}
extension MenuTouch {

    public static func remoteItem(_ item: MenuItem) {
        if let menu = menuKey[item.key] {
            menu.buffer.append(item)
        } else {
            let touchMenu = MenuTouch(isRemote: true)
            menuKey[item.key] = touchMenu
            touchMenu.buffer.append(item)
        }
    }
}
