//  Created by warren on 6/9/22.

import SwiftUI
import MuPar // Visitor

/// synchronize values with outside model, such as Flo
///
/// *Anys (s superlative) is needed for CGPoint and other multidimensional controls.
/// Should synchronize set and get of multiple values to avoid jitter
///
public protocol MuMenuSync {

    /// set single named value
    /// return false if already visit (may happen when Vm shared same node
    @discardableResult
    func setMenuAny(named: String,_ val: Double, _ visit: Visitor) -> Bool

    /// set multiple named values
    /// // return false if already visit (may happen when Vm shared same node
    @discardableResult
    func setMenuAnys(_ anys: [(String, Double)], _ visit: Visitor) -> Bool

    /// reset node to default value
    func setMenuDefault(_ visit: Visitor)

    /// get single named value
    func getMenuAny(named: String) -> Any?

    /// get multiple named values
    func getMenuAnys(named: [String]) -> [(String, Any?)]

    /// get single named range
    func getMenuRange(named: String) -> ClosedRange<Double>

    /// get multiple named ranges
    func getMenuRanges(named: [String]) -> [(String, ClosedRange<Double>)]

    /// callback from model to update leaf with new model values
    func syncMenuModel(_ any: Any, _ visit: Visitor)
}
