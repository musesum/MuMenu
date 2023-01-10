//  Created by warren on 9/10/22.


import Foundation
import Par

extension MuLeafValVm: MuLeafProtocol {

    public func refreshValue() {
        thumb[0] = normalizeNamed(nodeType.name)
        range = menuSync?.getRange(named: nodeType.name) ?? 0...1
    }

    public func updateLeaf(_ any: Any,_ visitor: Visitor) {
        if visitor.newVisit(hash) {
            editing = true
            switch any {
                case let v as Double:   thumb[0] = v 
                case let v as [Double]: thumb[0] = v[0]
                default: break
            }
            editing = false
            updateSync(visitor)
        }
    }

    public func valueText() -> String {
        if editing {
            return String(format: "%.2f", expanded)
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
