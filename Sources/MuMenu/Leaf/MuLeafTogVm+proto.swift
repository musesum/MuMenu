//  Created by warren on 9/10/22.


import Foundation
import Par

extension MuLeafTogVm: MuLeafProtocol {

    public func touchLeaf(_ touchState: MuTouchState) {
        if !editing, touchState.phase == .began  {
            thumb[0] = (thumb[0]==1.0 ? 0 : 1)
            editing = true
        } else if editing, touchState.phase.isDone() {
            editing = false
        }
        updateSync(Visitor())
    }

    public func refreshValue() {
        if let menuSync {
            thumb[0] = menuSync.getAny(named: nodeType.name) as? Double ?? 0
        }
    }
    
    public func updateLeaf(_ any: Any,_ visitor: Visitor) {
        if visitor.newVisit(hash) {
            editing = true
            switch any {
                case let v as Double:   thumb[0] = (v    < 1.0 ? 0 : 1)
                case let v as [Double]: thumb[0] = (v[0] < 1.0 ? 0 : 1)
                default: break
            }
            editing = false
            updateSync(visitor)
        }
    }

    private func updateSync(_ visitor: Visitor) {
        menuSync?.setAny(named: nodeType.name, thumb[0], visitor)
        updatePeers(visitor)
    }
    public func valueText() -> String {
        thumb[0] == 1.0 ? "1" : "0"
    }
    public func thumbOffset() -> CGSize {
        panelVm.axis == .vertical
        ? CGSize(width: 1, height: (1-thumb[0]) * panelVm.runway)
        : CGSize(width: thumb[0] * panelVm.runway, height: 1)
    }

    
}
