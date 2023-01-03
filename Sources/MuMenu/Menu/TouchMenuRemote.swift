//  Created by warren on 9/26/22

import UIKit

public class TouchMenu {
    public static var touchVms = [MuTouchVm]()
}

public class TouchMenuRemote {

    static var menuKey = [Int: TouchMenuRemote]()
    static var timerKey = [Int: Timer]()

    private let buffer = DoubleBuffer<MenuRemoteItem>(internalLoop: true)
    private let touchVm: MuTouchVm
    private let isRemote: Bool
    private let nodeVm: MuNodeVm?

    public init(_ touchVm: MuTouchVm,
         _ nodeVm: MuNodeVm?,
         isRemote: Bool) {

        self.touchVm = touchVm
        self.nodeVm = nodeVm
        self.isRemote = isRemote
        buffer.flusher = self
    }
}

extension TouchMenuRemote: BufferFlushDelegate {

    public typealias Item = MenuRemoteItem

    public func flushItem<Item>(_ item: Item) -> Bool {
        let item = item as! MenuRemoteItem
        let isDone = item.isDone()
        if isRemote {
            touchVm.gotoRemoteItem(item)
        } else {
            touchVm.updateTouchXY(item.nextXY, item.phase)
        }
        return isDone
    }
}

extension TouchMenuRemote {

    public static func remoteItem(_ item: MenuRemoteItem) {
        if let menu = menuKey[item.menuKey] {
            menu.buffer.append(item)
            return
        } else {
            for touchVm in TouchMenu.touchVms {
                if touchVm.corner.rawValue == item.corner {
                    addRemoteTouch(touchVm)
                    return
                }
            }
        }
        func addRemoteTouch(_ touchVm: MuTouchVm) {
            let touchMenu = TouchMenuRemote(touchVm, nil, isRemote: true)
            menuKey[item.menuKey] = touchMenu
            touchMenu.buffer.append(item)
        }
    }
}
