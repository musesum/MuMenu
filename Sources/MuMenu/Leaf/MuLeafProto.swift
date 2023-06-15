//  Created by warren on 9/10/22.

import Foundation
import MuPar // Visitor

/// MuLeaf* Model and View  protocols
public protocol MuLeafProtocol {

    /// update from model normalized range of 0...1, not touch gesture
    func updateFromModel(_ any: Any, _ visit: Visitor)

    /// title for control value
    func leafTitle() -> String

    /// title for control value
    func treeTitle() -> String

    /// position of thumb in control
    func thumbOffset() -> CGSize

    /// get value of thumb
    func refreshValue(_ visit: Visitor)

    /// update remote peers
    /// /// get value of thumb
    func refreshPeers(_ visit: Visitor)
    
    /// final upddate
    func syncVal(_ visit: Visitor)
    
}


