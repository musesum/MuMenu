//
//  File.swift
//  
//
//  Created by warren on 9/10/22.

import SwiftUI

extension MuLeafTapVm: MuLeafProtocol {

    public func touchLeaf(_ touchState: MuTouchState) {
        if touchState.phase == .began {
            thumb[0] = 1
            updateSync()
            updatePeers()
            editing = true
        } else if touchState.phase.isDone() {
            thumb[0] = 0
            updateSync()
            updatePeers()
            editing = false
        }
    }
    // MARK: - Value
    public override func refreshValue() {
        // no change
    }

    public override func updateLeaf(_ any: Any) {
        editing = true
        Schedule(0.125) {
            self.editing = false
        }
    }

    //MARK: - View

    public override func updateSync() {
        menuSync?.setAny(named: nodeType.name, thumb)
    }
    public override func valueText() -> String {
        editing ? "1" :  "0"
    }
    public override func thumbOffset() -> CGSize {
        CGSize(width: 0, height:  panelVm.runway)
    }
}
