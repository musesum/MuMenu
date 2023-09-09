//  Created by warren on 1/3/23.

import UIKit
import MuFlo // double buffer

public class TouchMenuLocal {
    
    static var menuKey = [Int: TouchMenuLocal]()

    private let buffer = DoubleBuffer<MenuItem>(internalLoop: true)
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
    @discardableResult
    public static func beginTouch(_ touch: UITouch) -> Bool {
        
        let touchXY = touch.preciseLocation(in: nil)

        for touchVm in CornerTouchVm.values {
            if let nodeVm = touchVm.hitTest(touchXY) {
                return addMenu(nodeVm)
            } else {
                for treeVm in touchVm.rootVm?.treeVms ?? [] {
                    if treeVm.treeBoundsPad.contains(touchXY) {
                        return addMenu()
                    }
                }
            }
            func addMenu(_ nodeVm: MuNodeVm? = nil) -> Bool {
                let touchMenu = TouchMenuLocal(touchVm, nodeVm, isRemote: false)
                let menuItem = MenuItem(touch, touchVm.corner)
                touchMenu.buffer.append(menuItem)
                let key = touch.hash
                menuKey[key] = touchMenu
                return true
            }
        }
        return false
    }
    
    public static func updateTouch(_ touch: UITouch) -> Bool {
        
        if let touchMenu = menuKey[touch.hash] {
            let corner = touchMenu.touchVm.corner
            touchMenu.buffer.append(MenuItem(touch, corner))
            return true
        }
        return false
    }
}

extension TouchMenuLocal: BufferFlushDelegate {

    public typealias Item = MenuItem

    public func flushItem<Item>(_ item: Item) -> Bool {
        let item = item as! MenuItem
        if let touch = item.item as? MenuTouchItem,
           let touchVm = CornerTouchVm[item.corner] {

            touchVm.updateTouchXY(touch.cgPoint, item.phase)
        }
        return item.isDone
    }
}

