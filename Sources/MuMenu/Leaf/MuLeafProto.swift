//  Created by warren on 9/10/22.

import Foundation
import MuPar // Visitor

/// MuLeaf* Model and View  protocols
public protocol MuLeafProtocol {

    /// update from model normalized range of 0...1, not touch gesture
    func updateLeaf(_ any: Any, _ visit: Visitor)

    /// title for control value
    func leafTitle() -> String

    /// title for control value
    func treeTitle() -> String

    /// position of thumb in control
    func thumbOffset() -> CGSize

    /// get value of thumb
    func refreshValue(_ visit: Visitor)

    /// animated upddate
    func syncNow(_ visit: Visitor)

    /// final upddate
    func syncNext(_ visit: Visitor)
    
}


