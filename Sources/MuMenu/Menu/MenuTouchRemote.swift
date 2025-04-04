//  created by musesum on 9/26/22

import UIKit
import MuFlo // double buffer
import MuPeer

@MainActor //____ 
public class MenuTouchRemote {

    nonisolated(unsafe) static var menuKey = [Int: MenuTouchRemote]()
    private let buffer = DoubleBuffer<MenuItem>(internalLoop: true)
    private let isRemote: Bool

    public init(isRemote: Bool) {
        
        self.isRemote = isRemote
        buffer.delegate = self
    }

}

extension MenuTouchRemote {

    public static func remoteItem(_ item: MenuItem) {
        if let menu = menuKey[item.key] {
            menu.buffer.append(item)
        } else {
            let touchMenu = MenuTouchRemote(isRemote: true)
            menuKey[item.key] = touchMenu
            touchMenu.buffer.append(item)
        }
    }
}
extension MenuTouchRemote: DoubleBufferDelegate {

    public typealias Item = MenuItem

    public func flushItem<Item>(_ item: Item) -> Bool {
        guard let menuItem = item as? MenuItem else { return false }
        let isDone = false // always listen for remote gestures
        switch menuItem.type {
        case .node, .leaf:
            if let cornerVm = menuItem.cornerVm {
                Task { @MainActor in
                    cornerVm.gotoMenuItem(menuItem)
                }
            }
        case .root:
            if case let .root(root) = menuItem.item {
                for tree in root.trees {
                    tree.showTree(isRemote)
                }
            }
        default: break
        }
        return isDone
    }
}
