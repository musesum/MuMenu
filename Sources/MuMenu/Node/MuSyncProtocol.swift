//  Created by warren on 6/9/22.

import SwiftUI
import Par // Visitor

/// synchronize values with outside model, such as Tr3
///
/// *Anys (s superlative) is needed for CGPoint and other multidimensional controls.
/// Should synchronize set and get of multiple values to avoid jitter
///
public protocol MuMenuSync {

    /// set single named value
    /// return false if already visit (may happen when Vm shared same node
    func setAny(named: String,_ any: Any, _ visitor: Visitor) -> Bool

    /// set multiple named values
    /// // return false if already visit (may happen when Vm shared same node
    func setAnys(_ anys: [(String, Any)], _ visitor: Visitor) -> Bool

    /// reset node to default value
    func resetDefault()

    /// get single named value
    func getAny(named: String) -> Any?

    /// get multiple named values
    func getAnys(named: [String]) -> [(String, Any?)]

    /// get single named range
    func getRange(named: String) -> ClosedRange<Double>

    /// get multiple named ranges
    func getRanges(named: [String]) -> [(String, ClosedRange<Double>)]

    /// callback from model to update leaf with new model values
    func syncModel(_ any: Any, _ visitor: Visitor)
}
