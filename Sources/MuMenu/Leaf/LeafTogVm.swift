//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// toggle control
public class LeafTogVm: LeafVm {

    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {

        super.init(menuTree, branchVm, prevVm)
        let visit = Visitor(0, .bind)
        updateFromFlo(menuTree.model˚, visit)
        syncVal(visit)
    }
    /// user touched leaf 
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {
        guard let (_,thumb,_) = runways.beginRunway(touchState.pointNow) else { return }
        if touchState.phase == .ended,
           touchState.touchEndedCount == 1  {

            thumb.value.x = (thumb.value.x == 1.0 ? 0 : 1)
            syncVal(visit)
        }
    }

    /// user double tapped a parent node
    override func tapLeaf() {
        guard let thumb = runways.thumb() else { return }
        thumb.value.x = (thumb.value.x == 1.0 ? 0 : 1)
        syncVal(Visitor(0,.user))
    }
    override public func leafTitle() -> String { menuTree.title  }
    override public func treeTitle() -> String {
        guard let thumb = runways.thumb() else { return "" }
        return (editing
                ? thumb.value.x == 1.0 ? "on" : "off"
                : menuTree.title)
    }
    override public func updateFromFlo(_ flo: Flo, _ visit: Visitor) {

        guard !visit.wasHere(leafHash), let scalar = flo.scalar else {
            return PrintLog("⁉️ LeafTogVm:: \(#function) err") }
        guard let thumb = runways.thumb() else { return }

        editing = true

        thumb.value.x = scalar.value < 1.0 ? 0 : 1      // scalar.value

        thumb.tween.x = (flo.hasPlugins
                         ? scalar.tween < 1.0 ? 0 : 1 // scalar.tween
                         : thumb.value.x)                // scalar.value

        editing = false

        syncVal(visit)
    }

    override public func thumbValueOffset(_ type: LeafRunwayType) -> CGSize {
        CGSize(width: 1, height: 1)
    }
    override public func thumbTweenOffset(_ type: LeafRunwayType) -> CGSize {
        CGSize(width: 1, height: 1)
    }
    override  public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb() else { return  }

        if  !visit.type.tween,
            !visit.type.bind {

            menuTree.model˚.setAnyExprs(("x", thumb.value.x), .fire, visit)
            updateLeafPeers(visit)
        }
        refreshView()
    }
}

