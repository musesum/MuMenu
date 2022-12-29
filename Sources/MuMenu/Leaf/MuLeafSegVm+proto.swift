//  Created by warren on 9/10/22.

import SwiftUI
import Par

extension MuLeafSegVm: MuLeafProtocol {

    public func refreshValue() {
        if let menuSync {
            range = menuSync.getRange(named: nodeType.name)
            if let val = menuSync.getAny(named: nodeType.name) as? Double {
                thumb[0] = scale(val, from: range, to: 0...1)
            } else {
                print("⁉️ refreshValue is not Double")
                thumb[0] = 0
            }
        }
    }
    
    public func updateLeaf(_ any: Any, _ visitor: Visitor) {
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
        range.upperBound > 1
        ? String(format: "%.f", scale(thumb[0], from: 0...1, to: range))
        : String(format: "%.1f", thumb[0])
    }

    public func thumbOffset() -> CGSize {
        panelVm.axis == .vertical
        ? CGSize(width: 1, height: (1-thumb[0]) * panelVm.runway)
        : CGSize(width: thumb[0] * panelVm.runway, height: 1)
    }

}
