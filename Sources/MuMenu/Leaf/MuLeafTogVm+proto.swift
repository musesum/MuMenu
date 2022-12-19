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
            thumb = (thumb==1 ? 0 : 1)
            updateView()
            editing = true
        } else if editing, touchState.phase.isDone() {
            editing = false
        }
    }
    // MARK: - Value

    public override func refreshValue() {
        thumb = CGFloat(nodeProto?.getAny(named: nodeType.name) as? Float ?? .zero)
    }
    
    public func updateLeaf(_ any: Any) {

        if let v = any as? Float {
            editing = true
            thumb = (v < 1 ? 0 : 1)
            editing = false
        }
    }

    // MARK: - View

    public func updateView() {
        nodeProto?.setAny(named: nodeType.name, thumb)
    }
    public override func valueText() -> String {
        thumb == 1 ? "1" : "0"
    }
    public override func thumbOffset() -> CGSize {
        panelVm.axis == .vertical
        ? CGSize(width: 1, height: (1-thumb) * panelVm.runway)
        : CGSize(width: thumb * panelVm.runway, height: 1)
    }

    
}
