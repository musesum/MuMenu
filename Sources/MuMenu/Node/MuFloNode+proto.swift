//  Created by warren on 9/10/22.

import SwiftUI
import MuFlo
import MuPar

extension MuFloNode: MuMenuSync {


    public func setMenuExprs(_ exprs: MuFlo.FloExprs?, _ val: Any, _ visit: MuPar.Visitor) -> Bool {
        guard let exprs else { return false }
        if visit.newVisit(hash) {
            modelFlo.setAny(val, .activate, visit)
            return true
        } else {
            return false
        }
    }

    public func setMenuDefault(_ visit: Visitor) {
        modelFlo.bindDefaults(visit)
        //?? modelFlo.activate()
    }

    // MARK: - get


//    public func getMenuExprs() -> MuFlo.FloExprs? {
//        if let menuSync,
//           let scalar = modelFlo.scalars().first
//        {
//            
//        }
//    }

    public func getMenuAny(named: String) -> Any? {

        let any = modelFlo.component(named: named)

        if let val = any as? FloValScalar {
            return val.now
        } else if let num = any as? Double {
            return num
        } else {
            return nil
        }
    }

//    public func getMenuRange(named: String) -> ClosedRange<Double> {
//        return modelFlo.getRange(named: named)
//    }
//    public func getMenuRanges(named: [String]) -> [(String,ClosedRange<Double>)] {
//        return modelFlo.getRanges(named: named)
//    }

    /// callback from flo
    public func syncMenuModel(_ any: Any, _ visit: Visitor) {
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
