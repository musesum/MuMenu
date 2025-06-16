//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// segmented LeafValVm control
public class LeafSegVm: LeafValVm {

    lazy var count: Double = { range.upperBound - range.lowerBound }()

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
    func ticks() -> [CGSize] {
        var result = [CGSize]()
        let length = self.panelVm.runLength(.runVal)

        if count < 1 { return [] }
        let span = (1/max(1,count))

        for i in stride(from: CGFloat(0), through: 1, by: span) {
            let offset = i * length
            let tick = (panelVm.menuType.vertical
                        ? CGSize(width:  0, height: offset)
                        : CGSize(width: offset,  height: 0))
            result.append(tick)
        }
        return result
    }

    override public func treeTitle() -> String {
        guard let thumb = runways.thumb() else { return "" }
        let value = (panelVm.menuType.vertical
                     ? thumb.value.y
                     : thumb.value.x)

        return (range.upperBound > 1
                ? String(format: "%.f", scale(value, from: 0...1, to: range))
                : String(format: "%.2f", value))
    }

    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb(.runVal) else { return  }

        // value of thumb on either vertical or horizonal axis
        let val = (panelVm.menuType.vertical
                   ? thumb.value.y
                   : thumb.value.x).quantize(count)
        syncVal2(visit, thumb, val)
    }
}

