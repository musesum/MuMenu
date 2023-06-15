//  Created by warren on 12/5/22.

import SwiftUI
import MuPar // Visitor
extension MuLeafPeerVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {}
    public func refreshPeers(_ visit: Visitor) {}
    public func updateFromModel(_ any: Any, _ visit: Visitor) {}
    public func leafTitle() -> String { "Bonjour" }
    public func treeTitle() -> String { "Bonjour" }
    public func thumbOffset() -> CGSize {  CGSize(width: 0, height:  panelVm.runway) }
    public func syncVal(_ visit: Visitor) {}


}
