//  created by musesum on 1/3/23.

import UIKit
import MuFlo // double buffer

public class TouchMenuLocal {
    
    static var menuKey = [Int: TouchMenuLocal]()

    private let buffer = CircleBuffer<MenuItem>(capacity: 3, internalLoop: true)
    private let cornerVm: CornerVm
    private let isRemote: Bool
    private let nodeVm: NodeVm?
    
    public init(_ cornerVm: CornerVm,
                _ nodeVm: NodeVm?,
                isRemote: Bool) {
        
        self.cornerVm = cornerVm
        self.nodeVm = nodeVm
        self.isRemote = isRemote
        buffer.delegate = self
    }
    @discardableResult
    public static func beginTouch(_ touch: UITouch) -> Bool {
        
        let touchXY = touch.preciseLocation(in: nil)

        for cornerVm in CornerOpVm.values {
            if let nodeVm = cornerVm.hitTest(touchXY) {
                return addMenu(nodeVm)
            } else {
                for treeVm in cornerVm.rootVm?.treeVms ?? [] {
                    if treeVm.treeBoundsPad.contains(touchXY) {
                        return addMenu()
                    }
                }
            }
            func addMenu(_ nodeVm: NodeVm? = nil) -> Bool {
                let touchMenu = TouchMenuLocal(cornerVm, nodeVm, isRemote: false)
                let menuItem = MenuItem(touch, cornerVm.corner)
                touchMenu.buffer.addItem(menuItem, bufType: .localBuf)
                let key = touch.hash
                menuKey[key] = touchMenu
                return true
            }
        }
        return false
    }
    
    public static func updateTouch(_ touch: UITouch) -> Bool {
        
        if let touchMenu = menuKey[touch.hash] {
            let corner = touchMenu.cornerVm.corner
            touchMenu.buffer.addItem(MenuItem(touch, corner), bufType: .localBuf)
            return true
        }
        return false
    }
}

extension TouchMenuLocal: CircleBufferDelegate {

    public typealias Item = MenuItem

    public func flushItem<Item>(_ item: Item, _ type: BufType) -> BufState {
        let item = item as! MenuItem
        if let touch = item.item as? MenuTouchItem,
           let cornerVm = CornerOpVm[item.cornerOp] {

            cornerVm.updateTouchXY(touch.cgPoint, item.phase)
        }
        return item.isDone ? .doneBuf : .nextBuf
    }
}

