//  Created by warren on 12/5/22.

import SwiftUI
import Par

extension MuLeafPeerVm: MuLeafProtocol {

    public func touchLeaf(_ touchState: MuTouchState) {
        if touchState.phase == .began {
            thumb[0] = 1
            editing = true
        } else if touchState.phase.isDone() {
            thumb[0] = 0
            editing = false
        } else {
            return
        }
        updateSync()
    }

    public func refreshValue() {
        // no change
    }

    public func updateLeaf(_ any: Any, _ visitor: Visitor) {
        visitor.startVisit(hash,visit)
        func visit() {
            self.editing = true
            Schedule(0.125) {
                self.editing = false
            }
            self.updateSync(visitor)
        }
    }
    
    private func updateSync(_ visitor: Visitor = Visitor()) {
        self.menuSync?.setAny(named: nodeType.name, thumb, visitor)
        self.updatePeers(visitor)
    }
    public func valueText() -> String {
        ""
    }
    public func thumbOffset() -> CGSize {
        CGSize(width: 0, height:  panelVm.runway)
    }

}
