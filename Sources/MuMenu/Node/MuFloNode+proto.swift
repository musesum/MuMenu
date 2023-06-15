//  Created by warren on 9/10/22.

import SwiftUI
import MuFlo
import MuPar

extension MuFloNode: MuMenuSync {

    public func setMenuExprs(_ any: Any,
                             _ visit: MuPar.Visitor) -> Bool {

        if visit.newVisit(hash) {
            modelFlo.setAny(any, .activate, visit)
            return true
        } else {
            return false
        }
    }

    public func setMenuDefault(_ visit: Visitor) {
        modelFlo.bindDefaults(visit)
        modelFlo.activate(visit)
    }

    /// callback from flo
    public func syncMenuModel(_ any: Any,
                              _ visit: Visitor) {
        
        guard let flo = any as? Flo else { return }

        for leaf in self.leafProtos {

            let nameScalars = flo.nameScalars()
            let vals = nameScalars.compactMap {
                $1.normalized()
            }
            DispatchQueue.main.async {
                leaf.updateLeaf(vals, visit)
            }
        }
    }
}
