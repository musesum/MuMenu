//  created by musesum on 12/20/21.

import SwiftUI
import MuExtensions

public class PanelVm {
 
    var nodes: [FloNode]
    var nodeType: NodeType
    var cornerAxis: CornerAxis
    let isVertical: Bool
    var count: CGFloat
    let maxNodes = CGFloat(7)
    var aspectSz = CGSize(width: 1, height: 1) /// multiplier aspect ratio

    init(nodes: [FloNode],
         treeVm: TreeVm) {

        self.nodes    = nodes
        self.count    = CGFloat(nodes.count)
        self.cornerAxis = treeVm.cornerAxis
        self.isVertical = treeVm.isVertical
        self.nodeType = (count > 1 ? .node : nodes.first?.nodeType ?? .node)
        setAspectFromType()
    }
    var spacing: CGFloat {
        if count <= maxNodes {
            return 0
        } else {
            // the last node always is in the same place on a panel
            // so, calculate the spacing of the prior nodes
            let nodeLen = Layout.diameter2 // node length
            let panelLen = (isVertical ? outer.height : outer.width)
            let priorLen = panelLen - nodeLen 
            let nodeSpace = priorLen / (count-1)
            let space = nodeSpace - nodeLen
            return space
        }
    }

    func setAspectFromType() {

        switch nodeType {
            case .none : aspect(1.0, 1.0)
            case .node : aspect(1.0, 1.0)
            case .tog  : aspect(1.0, 1.0)
            case .tap  : aspect(1.0, 1.0)

            case .val  : aspect(1.0, 4.0)
            case .vxy  : aspect(3.0, 3.0)
            case .seg  : aspect(1.0, 4.0)
            case .peer : aspect(6.0, 3.0)
        }
        func aspect(_ lo: CGFloat,_ hi: CGFloat) {
            aspectSz = isVertical || nodeType == .peer
            ? CGSize(width: lo, height: hi)
            : CGSize(width: hi, height: lo)
        }
    }

    // changed by type
    lazy var thumbRadius   : CGFloat = { Layout.radius - 1 }()
    lazy var thumbDiameter : CGFloat = { thumbRadius * 2 }()
    lazy var thumbSize     : CGSize = { CGSize(width: thumbRadius, height: thumbRadius) }()

    var runway: CGFloat {
        let result = isVertical
        ? inner.height - thumbDiameter
        : inner.width - thumbDiameter
        return result
    }

    lazy var runwayXY: CGPoint = {
        CGPoint(x: inner.height - thumbDiameter,
                y: inner.width - thumbDiameter)
    }()

    var inner: CGSize {
        
        let result =  aspectSz * Layout.diameter
        return result
    }

    var outer: CGSize {

        let result: CGSize

        switch nodeType {

            case .val, .seg:

                result = inner + (
                    isVertical
                    ? CGSize(width: Layout.padding2,
                             height: Layout.diameter2)
                    : CGSize(width: Layout.diameter2,
                             height: Layout.padding2))

            case .vxy, .peer: // header is always on top

                result = inner + CGSize(width: Layout.padding2,
                                        height: Layout.diameter2)

            case .none, .node, .tog, .tap:

                let length = Layout.diameter2 * min(count,maxNodes)
                let width  = isVertical ? Layout.diameter2 : length
                let height = isVertical ? length : Layout.diameter2

                result = CGSize(width: width, height: height)
        }
        return result
    }

    var titleSize: CGSize {
        if isVertical ||
            (nodes.count == 1 &&
             (nodes.first?.nodeType == .vxy ||
              nodes.first?.nodeType == .peer)) {

            // title is always on top
            return CGSize(width:  inner.width,
                          height: Layout.diameter - 8)
        } else {
            return CGSize(width:  Layout.diameter - 8,
                          height: Layout.diameter - 8)
        }
    }

    func normalizeTouch(xy: CGPoint) -> [Double] {
        let xMax = (inner.width  - thumbRadius)
        let yMax = (inner.height - thumbRadius)
        let xRange = thumbRadius...xMax
        let yRange = thumbRadius...yMax
        let xClamp = xy.x.clamped(to: xRange)
        let yClamp = xy.y.clamped(to: yRange)
        let xNormal = (xClamp - thumbRadius) / runway
        let yNormal = (yClamp - thumbRadius) / runway
        return [xNormal, 1-yNormal]
    }

    /// convert touch coordinates to 0...1
    func normalizeTouch(v: CGFloat) -> Double {
        if isVertical {
            let yMax = (inner.height - thumbRadius)
            let yClamp = v.clamped(to: thumbRadius...yMax)
            let yNormal = (yClamp - thumbRadius) / runway
            return 1.0 - yNormal // invert so that 0 is on bottom
        } else {
            let xMax = (inner.width  - thumbRadius)
            let xClamp = v.clamped(to: thumbRadius...xMax)
            let xNormal = (xClamp - thumbRadius) / runway
            return xNormal
        }
    }

    func updatePanelBounds(_ bounds: CGRect) -> CGRect {
        var result = bounds
        if isVertical {
            if bounds.minY < 0 {
                result.size.height += bounds.minY
                result.origin.y = 0
            }
        } else {
            if bounds.minX < 0 {
                result.size.width += bounds.minX
                result.origin.x = 0
            }
        }
        return result
    }

    func getBounds(from center: CGPoint) -> CGRect {
        let result = CGRect(x: center.x - outer.width/2,
                            y: center.y - outer.height/2,
                            width: outer.width,
                            height: outer.height)
        return result
    }
}
