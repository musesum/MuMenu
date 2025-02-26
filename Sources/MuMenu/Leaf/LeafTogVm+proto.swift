//  created by musesum on 9/10/22.

import Foundation
import MuFlo

extension LeafTogVm: LeafProtocol {
    
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
        thumb.value.x = valTween.value.x < 1.0 ? 0 : 1     // scalar.x.value
        thumb.tween.x = (menuTree.model˚.hasPlugins
                        ? valTween.tween.x < 1.0 ? 0 : 1
                        : thumb.value.x)
        editing = false
        syncVal(visit)
    }
    public func updateFromModel(_ flo: Flo,
                                _ visit: Visitor) {
        
        guard !visit.wasHere(leafHash), let scalar = flo.scalar else {
            return PrintLog("⁉️ LeafTogVm:: \(#function) err") }

        editing = true
        
        thumb.value.x = scalar.value < 1.0 ? 0 : 1      // scalar.value
        
        thumb.tween.x = (flo.hasPlugins
                        ? scalar.tween < 1.0 ? 0 : 1 // scalar.tween
                        : thumb.value.x)                // scalar.value
        
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
        CGSize(width: 1, height: 1)
    }
    public func thumbTweenOffset(_ runway: Runway) -> CGSize {
        CGSize(width: 1, height: 1)
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
