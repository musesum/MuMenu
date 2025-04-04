import UIKit
import MuFlo // double buffer

@MainActor //_____
public class MenuTouchLocal {
    
    nonisolated(unsafe) static var menuKey = [Int: MenuTouchLocal]()
    private let buffer = DoubleBuffer<MenuItem>(internalLoop: true)
    private let isRemote: Bool
    
    private let cornerVm: CornerVm
    private let nodeVm: NodeVm?
    
    public init(_ cornerVm: CornerVm,
                _ nodeVm: NodeVm?,
                isRemote: Bool) {
        
        self.cornerVm = cornerVm
        self.nodeVm = nodeVm
        self.isRemote = isRemote
        self.buffer.delegate = self
    }
    @discardableResult
    public static func beginTouch(_ touch: SendTouch) -> Bool {
        var continueTouch: Bool = false
        Task { @MainActor in
            for cornerVm in CornerOpVm.values {
                if let nodeVm = cornerVm.hitTest(touch.nextXY) {
                    addMenu(nodeVm)
                    continueTouch = true
                    break
                } else {
                    for treeVm in cornerVm.rootVm?.treeVms ?? [] {
                        if treeVm.treeBoundsPad.contains(touch.nextXY) {
                            addMenu()
                            continueTouch = true
                            break
                        }
                    }
                }
                @MainActor func addMenu(_ nodeVm: NodeVm? = nil) {
                    let touchMenu = MenuTouchLocal(cornerVm, nodeVm, isRemote: false)
                    let menuItem = MenuItem(touch, cornerVm.cornerOp)
                    touchMenu.buffer.append(menuItem)
                    let key = touch.hash
                    menuKey[key] = touchMenu
                }
            }
        }
        return continueTouch
    }
    
    public static func updateTouch(_ touch: SendTouch) -> Bool {
        
        if let touchMenu = menuKey[touch.hash] {
            var corner: CornerOp?
            let cornerVm = touchMenu.cornerVm
            DispatchQueue.main.sync {
                corner = cornerVm.cornerOp
            }
            if let corner {
                touchMenu.buffer.append(MenuItem(touch, corner))
            }
            return true
        }
        return false
    }
}

extension MenuTouchLocal: DoubleBufferDelegate {
    
    public typealias Item = MenuItem
    
    nonisolated public func flushItem<Item>(_ item: Item) -> Bool {
        guard let menuItem = item as? MenuItem else { return false }
        var isDone = false
        Task { @MainActor in
            if case let .touch(touchItem) = menuItem.item,
               let cornerVm = CornerOpVm[menuItem.cornerOp] {
                cornerVm.updateTouchXY(touchItem.cgPoint, menuItem.phase)
                isDone = menuItem.isDone // user ended gestures
            }
        }
        return isDone
    }
}
