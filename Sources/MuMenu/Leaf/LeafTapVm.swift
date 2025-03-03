//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

public class LeafTapVm: LeafVm {

    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {
        
        super.init(menuTree, branchVm, prevVm)
       
        let visit = Visitor(0, .bind)
        updateFromFlo(menuTree.model˚, visit)
        syncVal(visit)
    }
    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {

        guard let (_,thumb,_) = runways.beginRunway(touchState.pointNow) else { return }

        if !editing, touchState.phase == .began {

            editing = true
            thumb.value.x = 1
            syncVal(visit)

        } else if touchState.phase.done {

            editing = false
            thumb.value.x = 0
            syncVal(visit)
        }
    }
    /// user double tapped a parent node
    override func tapLeaf() {
        resetOrigin()
    }

    override public func leafTitle() -> String { menuTree.title }
    override public func treeTitle() -> String {
        guard let thumb = runways.thumb() else { return "" }
        return editing
        ? thumb.value.x == 1.0 ? "on" : "off"
        : menuTree.title
    }

    override public func updateFromFlo(_ flo: Flo, _ visit: Visitor) {

        guard !visit.wasHere(leafHash) else { return }
        guard let thumb = runways.thumb() else { return }

        editing = true

        if let scalar = flo.scalar {

            thumb.value.x = scalar.normalized(.value)
            thumb.tween.x = (flo.hasPlugins
                             ? scalar.normalized(.tween)
                             : thumb.value.x)
        } else {
            PrintLog("⁉️ LeafTapVm:: updateFromModel \(flo.path(3)) unknown type")
        }
        editing = false
        syncVal(visit)
    }


    override public func thumbValueOffset(_ type: LeafRunwayType) -> CGSize {
        let length = panelVm.runLength(type)
        return CGSize(width: 0, height:  length)
    }
    override public func thumbTweenOffset(_ type: LeafRunwayType) -> CGSize {
        let length = panelVm.runLength(type)
        return CGSize(width: 0, height: length)
    }

    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb() else { return }

        if  !visit.type.tween,
            !visit.type.bind {

            menuTree.model˚.setAnyExprs(("x", thumb.value.x), .fire, visit)
            updateLeafPeers(visit)
        }
        refreshView()
    }
    
}

