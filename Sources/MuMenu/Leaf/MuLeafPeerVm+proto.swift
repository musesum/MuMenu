//  Created by warren on 12/5/22.

import SwiftUI

extension MuLeafPeerVm: MuLeafProtocol {

    public func touchLeaf(_ touchState: MuTouchState) {
        if touchState.phase == .began {
            thumb[0] = 1
            updateView()
            editing = true
        } else if touchState.phase.isDone() {
            thumb[0] = 0
            updateView()
            editing = false
        }
    }
    // MARK: - Value
    public override func refreshValue() {
        // no change
    }

    public func updateLeaf(_ any: Any) {
        editing = true
        Schedule(0.125) {
            self.editing = false
        }
    }

    //MARK: - View

    public func updateView() {
        menuSync?.setAny(named: nodeType.name, thumb)
    }
    public override func valueText() -> String {
        ""
    }
    public override func thumbOffset() -> CGSize {
        CGSize(width: 0, height:  panelVm.runway)
    }

}
