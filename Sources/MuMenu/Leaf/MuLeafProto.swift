//  Created by warren on 9/10/22.

import Foundation
import Par // Visitor

/// MuLeaf* Model and View  protocols
public protocol MuLeafProtocol {

    /// update value from user touch gesture
    func touchLeaf(_ touchState: MuTouchState)

    /// update from model normalized range of 0...1, not touch gesture
    func updateLeaf(_ any: Any, _ visitor: Visitor)

    /// title for control value
    func valueText() -> String

    /// position of thumb in control
    func thumbOffset() -> CGSize

    /// get value of thumb
    func refreshValue()

}


