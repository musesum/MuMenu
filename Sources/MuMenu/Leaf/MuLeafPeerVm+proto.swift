//  created by musesum on 12/5/22.

import SwiftUI
import MuFlo
extension MuLeafPeerVm: MuLeafProtocol {

    public func refreshValue(_ _: Visitor) {}
    public func refreshPeers(_ _: Visitor) {}
    public func updateFromThumbs(_ _: Thumbs, _ _: Visitor) {}
    public func updateFromModel(_ _: Flo, _ _: Visitor) {}
    public func leafTitle() -> String { "Bonjour" }
    public func treeTitle() -> String { "Bonjour" }
    public func thumbValOffset() -> CGSize {  CGSize(width: 0, height:  panelVm.runway) }
    public func thumbTweOffset() -> CGSize {  CGSize(width: 0, height:  panelVm.runway) }
    public func syncVal(_ _: Visitor) {}


}
