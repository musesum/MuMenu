//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// segmented control
public class LeafSegVm: LeafVm {

    var range: ClosedRange<Double> = 0...1

    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          icon: String = "") {

        super.init(menuTree, branchVm, prevVm)

        setRanges()

        let visit = Visitor(0, .bind)
        updateFromFlo(menuTree.model˚, visit)
        syncVal(visit)
        updatePanelSizes()
    }

    /// normalize to and from scalar range
    func setRanges() {
        if let exprs = menuTree.model˚.exprs {
            if let x = exprs.nameAny["x"] as? Scalar {
                range = x.range()
            } else if let y = exprs.nameAny["y"] as? Scalar {
                range = y.range()
            } else if let scalar = exprs.nameAny.values.first as? Scalar {
                range = scalar.range()
            }
        }
    }   

    lazy var count: Double = {
        range.upperBound - range.lowerBound
    }()


    /// adjust branch and panel sizes for smaller segments
    func updatePanelSizes() {
        let size = panelVm.isVertical
        ? CGSize(width: 1, height: count.clamped(to: 2...4))
        : CGSize(width: count.clamped(to: 2...4), height: 1)

        branchVm.panelVm.aspectSz = size
        panelVm.aspectSz = size
    }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
    func ticks() -> [CGSize] {

        var result = [CGSize]()
        let length = panelVm.runLength(.runXY)
        let radius = panelVm.thumbRadius
        let count = Float(range.upperBound - range.lowerBound)
        if count < 1 { return [] }
        let span = (1/max(1,count))
        let margin = Layout.radius - 2

        for v in stride(from: 0, through: Float(1), by: span) {

            let ofs = CGFloat(v) * length + radius
            let size = panelVm.isVertical
            ? CGSize(width: margin, height: ofs)
            : CGSize(width: ofs, height: margin)
            result.append (size)
        }
        return result
    }

    /// `touchBegin` inside thumb will Not move thumb.
    /// So, determing delta from center at touchState.begin
    var thumbBeginΔ = Double(0)


    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {
        
        editing = runways.touchLeaf(touchState)
        syncVal(visit)
    }
    /// user double tapped a parent node
    override func tapLeaf() {
        resetOrigin()
    }
    override public func leafTitle() -> String {
        guard let thumb = runways.thumb() else { return "" }
        return range.upperBound > 1
        ? String(format: "%.f", scale(thumb.value.x, from: 0...1, to: range))
        : String(format: "%.1f", thumb.value.x)
    }
    override public func treeTitle() -> String { menuTree.title }
    
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
            PrintLog("⁉️ LeafSegVm:: updateFromModel \(flo.path(3)) unknown type")
        }
        editing = false
        syncVal(visit)
    }

    override public func thumbValueOffset(_ type: LeafRunwayType) -> CGSize {
        guard let thumb = runways.thumb(type) else { return .zero }
        let length = panelVm.runLength(type)
        return (panelVm.isVertical
                ? CGSize(width: 1, height: (1-thumb.value.x) * length)
                : CGSize(width: thumb.value.x * length, height: 1))
    }
    override public func thumbTweenOffset(_ type: LeafRunwayType) -> CGSize {
        guard let thumb = runways.thumb(type) else { return .zero }
        let length = panelVm.runLength(type)
        return (panelVm.isVertical
                ? CGSize(width: 1, height: (1-thumb.tween.x) * length)
                : CGSize(width: thumb.tween.x * length, height: 1))
    }
    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb() else { return }
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

