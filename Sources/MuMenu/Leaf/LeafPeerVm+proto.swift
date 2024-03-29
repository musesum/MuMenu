//  created by musesum on 12/5/22.

import SwiftUI
import MuFlo
extension LeafPeerVm: LeafProtocol {

    public func refreshValue(_ _: Visitor) {}
    public func refreshPeers(_ _: Visitor) {}
    public func updateFromThumbs(_ _: ValTween, _ _: Visitor) {}
    public func updateFromModel(_ _: Flo, _ _: Visitor) {}
    public func leafTitle() -> String { "Bonjour" }
    public func treeTitle() -> String { "Bonjour" }
    public func thumbValOffset(_:RunwayType) -> CGSize {  CGSize(width: 0, height:  panelVm.runway(.none)) }
    public func thumbTweOffset(_:RunwayType) -> CGSize {  CGSize(width: 0, height:  panelVm.runway(.none)) }
    public func syncVal(_ _: Visitor) {}


}
