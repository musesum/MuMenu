//  Created by warren on 6/9/22.

import SwiftUI
import MuFlo
import MuPar // Visitor

/// synchronize values with outside model, such as Flo
///
/// *Anys (s superlative) is needed for CGPoint and other multidimensional controls.
/// Should synchronize set and get of multiple values to avoid jitter
///
public protocol MuMenuSync {

    @discardableResult
    func setMenuExprs(_ exprs: FloExprs?,_ val: Any, _ visit: Visitor) -> Bool

    /// reset node to default value
    func setMenuDefault(_ visit: Visitor)

    /// callback from model to update leaf with new model values
    func syncMenuModel(_ any: Any, _ visit: Visitor)
}
