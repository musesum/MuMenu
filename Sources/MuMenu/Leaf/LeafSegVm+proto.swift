//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo

extension LeafSegVm: LeafProtocol {

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
        thumb.value = valTween.value
        thumb.tween = (menuTree.model˚.hasPlugins
                       ? valTween.tween
                       : thumb.value)
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
            PrintLog("⁉️ LeafSegVm:: updateFromModel \(flo.path(3)) unknown type")
        }
        editing = false
        syncVal(visit)
    }

    public func leafTitle() -> String {
        range.upperBound > 1
        ? String(format: "%.f", scale(thumb.value.x, from: 0...1, to: range))
        : String(format: "%.1f", thumb.value.x)
    }
    public func treeTitle() -> String {
        menuTree.title
    }
    public func thumbValueOffset(_ runway: Runway) -> CGSize {
        let length = panelVm.runLength(runway)
        return (panelVm.isVertical
                ? CGSize(width: 1, height: (1-thumb.value.x) * length)
                : CGSize(width: thumb.value.x * length, height: 1))
    }
    public func thumbTweenOffset(_ runway: Runway) -> CGSize {
        let length = panelVm.runLength(runway)
        return (panelVm.isVertical
                ? CGSize(width: 1, height: (1-thumb.tween.x) * length)
                : CGSize(width: thumb.tween.x * length, height: 1))
    }
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }

        if  !visit.type.tween,
            !visit.type.bind {

            let expanded = scale(thumb.value.x.quantize(count), from: 0...1, to: range)
            menuTree.model˚.setAnyExprs(expanded, .fire, visit)
            updateLeafPeers(visit)
        }
        if !menuTree.model˚.hasPlugins {
            thumb.tween.x = thumb.value.x
        }
        refreshView()
    }
}
