//  Created by warren on 1/3/23.

import UIKit

public class TouchMenuLocal {
    
    static var menuKey = [Int: TouchMenuLocal]()
    static var timerKey = [Int: Timer]()
    
    private let buffer = DoubleBuffer<MenuLocalItem>(internalLoop: true)
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
    
    public static func beginTouch(_ touch: UITouch) -> Bool {
        
        let nextXY = touch.preciseLocation(in: nil)

        for touchVm in TouchMenu.touchVms {
            if let nodeVm = touchVm.hitTest(nextXY) {
                
                let touchMenu = TouchMenuLocal(touchVm, nodeVm, isRemote: false)
                let menuLocalItem = MenuLocalItem(touch)
                touchMenu.buffer.append(menuLocalItem)
                let key = touch.hash
                menuKey[key] = touchMenu
                return true
            }
        }
        return false
    }
    
    public static func updateTouch(_ touch: UITouch) -> Bool {
        
        if let touchMenu = menuKey[touch.hash] {
            touchMenu.buffer.append(MenuLocalItem(touch))
            return true
        }
        return false
    }
}

extension TouchMenuLocal: BufferFlushDelegate {

    public typealias Item = MenuLocalItem

    public func flushItem<Item>(_ item: Item) -> Bool {
        let item = item as! MenuLocalItem
        let point = CGPoint(x: CGFloat(item.xy[0]),
                            y: CGFloat(item.xy[1]))
        touchVm.updateTouchXY(point, item.phase)
        return item.isDone
    }
}

