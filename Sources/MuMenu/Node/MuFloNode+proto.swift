//  Created by warren on 9/10/22.

import SwiftUI
import MuFlo
import MuPar

extension MuFloNode: MuMenuSync {

    public func setMenuAny(named: String,_ val: Double, _ visit: Visitor) -> Bool {
        if visit.newVisit(hash) {
            modelFlo.setNameVals([(named,val)], .activate, visit)
            return true
        } else {
            return false
        }
    }
    public func setMenuAnys(_ anys: [(String, Double)], _ visit: Visitor) -> Bool {
        if visit.newVisit(hash) {
            modelFlo.setNameVals(anys, .activate, visit)
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
    public func getMenuAnys(named: [String]) -> [(String,Any?)] {

        var result = [(String,Any?)]()
        let comps = modelFlo.components(named: named)
        for (name, any) in comps {
            if let val = any as? FloValScalar {
                result.append((name, val.now))
            } else if let num = any as? Float {
                result.append((name, num))
            } else {
                result.append((name, nil))
            }
        }
        return result
    }
    public func getMenuRange(named: String) -> ClosedRange<Double> {

        let component = modelFlo.component(named: named)

        let range = ((component as? FloValScalar)?.range() ??
                (modelFlo.val as? FloValScalar)?.range() ??
                0...1)
        return range 
    }
    public func getMenuRanges(named: [String]) -> [(String,ClosedRange<Double>)] {

        var result = [(String,ClosedRange<Double>)]()

        let comps = modelFlo.components(named: named)
        for (name, component) in comps {

            let range = ((component as? FloValScalar)?.range() ??
                         (modelFlo.val as? FloValScalar)?.range() ??
                         0...1)

            result.append((name,range))
        }
        return result
    }

    /// callback from flo
    public func syncMenuModel(_ any: Any, _ visit: Visitor) {
        guard let flo = any as? Flo else { return }

        for leaf in self.leafProtos {

            let comps = flo.components(named: MuNodeLeafNames)
            let vals = comps.compactMap { ($1 as? FloValScalar)?.normalized() }

            DispatchQueue.main.async {
                leaf.updateLeaf(vals, visit)
            }
        }
    }
}
