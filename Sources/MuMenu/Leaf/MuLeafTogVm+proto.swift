//  Created by warren on 9/10/22.


import Foundation
import Par

extension MuLeafTogVm: MuLeafProtocol {

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

    public func valueText() -> String {
        if editing {
            return thumb[0] == 1.0 ? "1" : "0"
        } else {
            return node.title
        }
    }

    public func thumbOffset() -> CGSize {
        panelVm.isVertical
        ? CGSize(width: 1, height: (1-thumb[0]) * panelVm.runway)
        : CGSize(width: thumb[0] * panelVm.runway, height: 1)
    }

    
}
