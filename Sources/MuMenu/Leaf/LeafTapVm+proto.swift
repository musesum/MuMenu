//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo

extension LeafTapVm: LeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        updateFromModel(menuTree.model˚, visit)
        refreshPeers(visit)
    }
    
    public func refreshPeers(_ visit: Visitor) {
        guard !visit.type.tween else { return }
        visit.nowHere(leafHash)
        syncVal(Visitor(leafHash))
    }
    
    /// always from remote
    public func remoteValTween(_ valTween: ValTween,
                                 _ visit: Visitor) {

        editing = true
        thumb.value = valTween.value // scalar.x.val
        thumb.tween = (menuTree.model˚.hasPlugins ? valTween.tween : thumb.value)
        editing = false
        syncVal(visit)
    }
    public func updateFromModel(_ flo: Flo,
                                _ visit: Visitor) {

        guard !visit.wasHere(leafHash) else { return }

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



    public func leafTitle() -> String {
        menuTree.title
    }
    public func treeTitle() -> String {
        editing
        ? thumb.value.x == 1.0 ? "on" : "off"
        : menuTree.title
    }
    public func thumbValueOffset(_ runway: Runway) -> CGSize {
        let length = panelVm.runLength(runway)
        return CGSize(width: 0, height:  length)
    }
    public func thumbTweenOffset(_ runway: Runway) -> CGSize {
        let length = panelVm.runLength(runway)
        return CGSize(width: 0, height: length)
    }

    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }

        if  !visit.type.tween,
            !visit.type.bind {

            menuTree.model˚.setAnyExprs(("x", thumb.value.x), .fire, visit)
            updateLeafPeers(visit)
        }
        refreshView()
    }
    
}
