//
//  File.swift
//  
//
//  Created by warren on 9/10/22.
//

import Foundation

extension MuLeafTogVm: MuLeafProtocol {

    public func touchLeaf(_ touchState: MuTouchState) {
        if !editing, touchState.phase == .began  {
            thumb[0] = (thumb[0]==1.0 ? 0 : 1)
            updateView()
            editing = true
        } else if editing, touchState.phase.isDone() {
            editing = false
        }
    }
    // MARK: - Value

    public override func refreshValue() {
        if let menuSync {
            thumb[0] = menuSync.getAny(named: nodeType.name) as? Double ?? 0
        }
    }
    
    public func updateLeaf(_ any: Any) {

        if let v = any as? Float {
            editing = true
            thumb[0] = (v < 1.0 ? 0 : 1)
            editing = false
        }
    }

    // MARK: - View

    public func updateView() {
        menuSync?.setAny(named: nodeType.name, thumb)
    }
    public override func valueText() -> String {
        thumb[0] == 1.0 ? "1" : "0"
    }
    public override func thumbOffset() -> CGSize {
        panelVm.axis == .vertical
        ? CGSize(width: 1, height: (1-thumb[0]) * panelVm.runway)
        : CGSize(width: thumb[0] * panelVm.runway, height: 1)
    }

    
}
