//  Created by warren on 9/10/22.


import Foundation
import MuFlo
import MuPar

extension MuLeafTogVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        updateFromModel(node.modelFlo, visit)
        refreshPeers(visit)
    }
    public func refreshPeers(_ visit: Visitor) {
        visit.nowHere(self.hash)
        if visit.from.user {
            syncVal(Visitor(self.hash))
            updateLeafPeers(visit)
        }
    }
    /// always from remote
    public func updateFromThumbs(_ thumbs: Thumbs,
                                 _ visit: Visitor) {
        editing = true
        thumbVal[0] = thumbs[0][0] < 1.0 ? 0 : 1    // scalar.x.val
        thumbTwe[0] = (node.modelFlo.hasPlugins
                       ? thumbs[1][0] < 1.0 ? 0 : 1  // scalar.x.twe
                       : thumbs[0][0] < 1.0 ? 0 : 1) // scalar.x.val

    }
    public func updateFromModel(_ flo: Flo,
                                _ visit: Visitor) {

        guard !visit.wasHere(hash) else { return }

        editing = true

        if let exprs = flo.exprs,
           let v = (exprs.nameAny["_0"] as? FloValScalar ??
                    exprs.nameAny.values.first as? FloValScalar) {

            thumbVal[0] = v.val < 1.0 ? 0 : 1
            thumbTwe[0] = (flo.hasPlugins
                           ? v.twe < 1.0 ? 0 : 1
                           : thumbVal[0])
        } else {
            print("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
    }


    public func leafTitle() -> String {
        node.title
    }
    public func treeTitle() -> String {
        editing
        ? thumbVal[0] == 1.0 ? "on" : "off"
        : node.title
    }
    
    public func thumbValOffset() -> CGSize {
        CGSize(width: 1, height: 1)
    }
    public func thumbTweOffset() -> CGSize {
        CGSize(width: 1, height: 1)
    }
    public func syncVal(_ visit: Visitor) {
        if visit.newVisit(hash) {
            node.modelFlo.setAny(thumbVal[0], .activate, visit)
            refreshView()
        }
    }
    
}
