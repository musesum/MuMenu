//  Created by warren on 12/5/22.

import SwiftUI
import Par // Visitor
extension MuLeafPeerVm: MuLeafProtocol {

    public func refreshValue(_ visitor: Visitor) {}
    public func updateLeaf(_ any: Any, _ visitor: Visitor) {}
    public func leafTitle() -> String { "Bonjour" }
    public func treeTitle() -> String { "Bonjour" }
    public func thumbOffset() -> CGSize {  CGSize(width: 0, height:  panelVm.runway) }
    public func syncNow(_ visitor: Visitor) {}
    public func syncNext(_ visitor: Visitor) {}


}
