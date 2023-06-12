//  Created by warren on 9/10/22.


import Foundation
import MuPar

extension MuLeafValVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        if let scalar = node.modelFlo.scalars().first
        {
            range = scalar.range()
            let val = scalar.val //??? .val???
            thumbNext[0] = scale(val, from: range, to: 0...1)
        } else {
            print("⁉️ refreshValue: scalar not found")
            thumbNext[0] = 0
        }
        refreshPeers(visit)
    }
    public func refreshPeers(_ visit: Visitor) {
        if !visit.from.tween { //... different
            visit.nowHere(self.hash) //... different
            syncNext(Visitor(self.hash))
            updateLeafPeers(visit)
        }
    }
    
    /// update from model - not touch
    public func updateLeaf(_ any: Any,_ visit: Visitor) {

        visit.nowHere(hash)
        editing = true
        switch any {
            case let v as Double:   thumbNext[0] = v
            case let v as [Double]: thumbNext[0] = v[0]
            default: break
        }
        editing = false
        syncNext(visit)
        updateLeafPeers(visit)
    }

    public func leafTitle() -> String {
        String(format: "%.2f", expanded)
    }
    public func treeTitle() -> String {
        node.title
    }
    public func thumbOffset() -> CGSize {
        panelVm.isVertical
        ? CGSize(width: 1, height: (1-thumbNext[0]) * panelVm.runway)
        : CGSize(width: thumbNext[0] * panelVm.runway, height: 1)
    }

    public func syncNext(_ visit: Visitor) {
        let expanded = scale(thumbNext[0], from: 0...1, to: range)
        refreshView()
    }
}
