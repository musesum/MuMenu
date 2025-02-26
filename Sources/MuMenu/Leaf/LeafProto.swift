//  created by musesum on 9/10/22.

import Foundation
import MuFlo

/// MuLeaf* Model and View  protocols
public protocol LeafProtocol {

    /// update from model normalized range of 0...1, not touch gesture
    func updateFromModel(_ flo: Flo, _ visit: Visitor)
    func remoteValTween(_ valTween: ValTween, _ visit: Visitor)

    func leafTitle() -> String /// title for control value
    func treeTitle() -> String /// title for control value

    func thumbValueOffset(_ : Runway) -> CGSize /// position of thumb in control
    func thumbTweenOffset(_ : Runway) -> CGSize /// position of tween in control
    func refreshValue(_ visit: Visitor)  /// get value of thumb
    func refreshPeers(_ visit: Visitor) /// update remote peers
    func syncVal(_ visit: Visitor) /// final upddate
}


