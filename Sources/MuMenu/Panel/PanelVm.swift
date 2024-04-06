//  created by musesum on 12/20/21.

import SwiftUI
import MuFlo

public class PanelVm {
 
    var nodes: [FloNode]
    var nodeType: NodeType
    var cornerItem: CornerItem
    let isVertical: Bool
    var count: CGFloat
    let maxNodes = CGFloat(7)
    var aspectSz = CGSize(width: 1, height: 1) /// multiplier aspect ratio

    init(nodes: [FloNode],
         treeVm: TreeVm) {

        self.nodes = nodes
        self.count = CGFloat(nodes.count)
        self.cornerItem = treeVm.cornerItem
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
        case .xy   : aspect(3.0, 3.0)
        case .xyz  : aspect(4.0, 3.5)
        case .seg  : aspect(1.0, 4.0)
        case .peer : aspect(6.0, 3.0)
        case .hand : aspect(4.0, 3.5)
        }
        func aspect(_ lo: CGFloat,_ hi: CGFloat) {
            aspectSz = isVertical || nodeType == .peer
            ? CGSize(width: lo, height: hi)
            : CGSize(width: hi, height: lo)
        }
    }

    // changed by type
    var thumbRadius: Double { Double(Layout.radius - 1) }

    func thumbDiameter(_ runwayType: RunwayType) -> Double {
        switch runwayType {
        case .x,.y,.z : return thumbRadius
        default       : return thumbRadius * 2
        }
    }

    func runway(_ runwayType: RunwayType) -> Double {
        let inner = inner(runwayType)
        let diameter = thumbDiameter(runwayType)
        let run: Double
        switch runwayType {
        case .x     : run = inner.width  - diameter
        case .y,.z  : run = inner.height - diameter
        default     : run = (isVertical
                             ? inner.height - diameter
                             : inner.width  - diameter)
        }
        return run
    }

    var runwayXY: CGPoint {
        let innerXY = inner(.xy)
        return CGPoint(x: innerXY.height - thumbDiameter(.xy),
                       y: innerXY.width  - thumbDiameter(.xy))
    }
    var runwayXYZ: CGPoint {
        let innerXYZ = inner(.xyz)
        return CGPoint(x: innerXYZ.height - thumbDiameter(.xy),
                       y: innerXYZ.width  - thumbDiameter(.xy))
    }

    var inner: CGSize {
        
        let result =  aspectSz * Layout.diameter
        return result
    }

    func inner(_ runwayType: RunwayType ) -> CGSize {
        let d = Layout.diameter
        switch runwayType {
        case .x   : return CGSize(width: d * 2.5, height: d * 0.5)
        case .y   : return CGSize(width: d * 0.5, height: d * 2.5)
        case .xyz : return CGSize(width: d * 3.0, height: d * 3.0)
        case .z   : return CGSize(width: d * 0.5, height: d * 2.5)
        default   : return aspectSz * d
        }
    }
    var outer: CGSize {

        let result: CGSize

        switch nodeType {

        case .val, .seg:

            result = inner + (
                isVertical
                ? CGSize(width: Layout.padding2 , height: Layout.diameter2)
                : CGSize(width: Layout.diameter2, height: Layout.padding2))

        case .xyz:

            result = inner + CGSize(width: Layout.padding2*3,
                                    height: Layout.diameter2 )

        case .xy, .hand, .peer: // header is always on top

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
             (nodes.first?.nodeType == .xy ||
              nodes.first?.nodeType == .peer)) {

            // title is always on top
            return CGSize(width:  inner.width,
                          height: Layout.diameter - 8)
        } else {
            return CGSize(width:  Layout.diameter - 8,
                          height: Layout.diameter - 8)
        }
    }
    func normalizeTouch(xy: SIMD2<Double>) -> SIMD3<Double>{
        let runway = runway(.xy)
        let xMax = (inner.width  - thumbRadius)
        let yMax = (inner.height - thumbRadius)
        let xRange = thumbRadius...xMax
        let yRange = thumbRadius...yMax
        let xClamp = xy.x.clamped(to: xRange)
        let yClamp = xy.y.clamped(to: yRange)
        let xNormal = (xClamp - thumbRadius) / runway
        let yNormal = (yClamp - thumbRadius) / runway
        return SIMD3<Double>(xNormal, 1-yNormal, 0)
    }
    func normalizeTouch(xyz: SIMD3<Double>) -> SIMD3<Double> {
        let runway = runway(.xyz)
        let xMax = (inner.width  - thumbRadius)
        let yMax = (inner.height - thumbRadius)
        let zMax = (inner.height - thumbRadius)
        let xRange = thumbRadius...xMax
        let yRange = thumbRadius...yMax
        let zRange = thumbRadius...zMax
        let xClamp = xyz.x.clamped(to: xRange)
        let yClamp = xyz.y.clamped(to: yRange)
        let zClamp = xyz.z.clamped(to: zRange)
        let xNormal = (xClamp - thumbRadius) / runway
        let yNormal = (yClamp - thumbRadius) / runway
        let zNormal = (zClamp - thumbRadius) / runway
        return SIMD3<Double>(xNormal, 1-yNormal, zNormal)
    }

    /// convert touch coordinates to 0...1
    func normalizeTouch(v: Double) -> Double {
        let runway = runway(.xy)
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
