//  Created by warren on 9/26/22

import UIKit

public var CornerTouchVm = [Int: MuTouchVm]()

public class TouchMenu {

    static var menuKey = [Int: TouchMenu]()
    private let buffer = DoubleBuffer<MenuItem>(internalLoop: true)
    private let isRemote: Bool

    public init(isRemote: Bool) {

        self.isRemote = isRemote
        buffer.flusher = self
    }
}

extension TouchMenu: BufferFlushDelegate {

    public typealias Item = MenuItem

    public func flushItem<Item>(_ item: Item) -> Bool {
        let item = item as! MenuItem

        if isRemote {
            if let _ = item.node {
                item.touchVm?.gotoNodeItem(item)
            } else if let root = item.root {
                for tree in root.trees {
                    tree.showTree(isRemote)
                }
            }
        } else if let touch = item.touch {
            item.touchVm?.updateTouchXY(touch.cgPoint, item.phase)
        }
        return false // never invalidate internal timer
    }
}

extension TouchMenu {

    public static func remoteItem(_ item: MenuItem) {
        if let menu = menuKey[item.key] {
            menu.buffer.append(item)
        } else {
            let touchMenu = TouchMenu(isRemote: true)
            menuKey[item.key] = touchMenu
            touchMenu.buffer.append(item)
        }
    }
}
