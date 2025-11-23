//  created by musesum on 1/3/23.

import UIKit
import MuFlo // double buffer
import MuPeers // DataFrom

/// user touched menu locally, so buffer menuTouchs in CircleBuffer
@MainActor
public class TouchMenuLocal {
    
   static var menuKey = [Int: TouchMenuLocal]()

    private let buffer: CircleBuffer<MenuItem>
    private let cornerVm: CornerVm
    private let isRemote: Bool
    private let nodeVm: NodeVm?
    
    public init(_ cornerVm: CornerVm,
                _ nodeVm: NodeVm?,
                isRemote: Bool) {
        
        self.cornerVm = cornerVm
        self.nodeVm = nodeVm
        self.isRemote = isRemote
        self.buffer = CircleBuffer<MenuItem>()
        buffer.delegate = self
    }
    /// hit test if touch is on menu
    public static func beginTouch(_ location : CGPoint,
                                  _ phase    : Int,
                                  _ hash     : Int) -> Bool
    {
        for cornerVm in MenuTypeCornerVm.values {
            if let nodeVm = cornerVm.hitTest(location) {
                return addMenu(nodeVm)
            } else {
                for treeVm in cornerVm.rootVm?.treeVms ?? [] {
                    if !treeVm.showTree.state.hidden,
                        treeVm.treeBoundsPad.contains(location) {
                        return addMenu()
                    }
                }
            }
            func addMenu(_ nodeVm: NodeVm? = nil) -> Bool {
                let touchMenu = TouchMenuLocal(cornerVm, nodeVm, isRemote: false)
                let menuItem = MenuItem(location,phase,hash, cornerVm.menuType)
                touchMenu.buffer.addItem(menuItem, from: .local)
                menuKey[hash] = touchMenu
                return true
            }
        }
        return false
    }

    public static func updateTouch(_ location : CGPoint,
                                   _ phase    : Int,
                                   _ hash     : Int) -> Bool {

        if let touchMenu = menuKey[hash] {
            let corner = touchMenu.cornerVm.menuType
            touchMenu.buffer.addItem(MenuItem(location, phase, hash, corner), from: .local)
            if phase == 3 {
                menuKey.removeValue(forKey: hash)
            }
            return true
        }
        return false
    }
}

extension TouchMenuLocal: CircleBufferDelegate {

    public typealias Item = MenuItem

    public func flushItem<Item>(_ item: Item, _ from: DataFrom) -> BufState {
        let item = item as! MenuItem
        if let touch = item.item as? MenuTouchItem,
           let cornerVm = MenuTypeCornerVm[item.menuType.rawValue] {

            cornerVm.updateTouchXY(touch.cgPoint, item.phase)
        }
        return item.isDone ? .doneBuf : .nextBuf
    }
}

