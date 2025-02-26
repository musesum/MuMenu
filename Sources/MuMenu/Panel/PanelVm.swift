//  created by musesum on 12/20/21.

import SwiftUI
import MuFlo

public class PanelVm {

    let branchVm: BranchVm
    var menuTrees: [MenuTree]
    var nodeType: NodeType
    var corner: Corner
    let isVertical: Bool
    var count: CGFloat
    let maxNodes = CGFloat(7)
    var aspectSz = CGSize(width: 1, height: 1) /// multiplier aspect ratio
    var columns: Int


    init(branchVm: BranchVm,
         menuTrees: [MenuTree],
         treeVm: TreeVm,
         columns: Int) {

        self.branchVm = branchVm
        self.menuTrees = menuTrees
        self.columns = columns
        self.count = CGFloat(menuTrees.count)
        self.corner = treeVm.corner
        self.isVertical = treeVm.isVertical
        self.nodeType = (count > 1 ? .node : menuTrees.first?.nodeType ?? .node)
        setAspectFromType()
    }
    var spacing: CGFloat {
        if count <= maxNodes {
            return 0
        } else {
            // the last node always is in the same place on a panel
            // so, calculate the spacing of the prior nodes
            let nodeLen = Layout.diameter2 // node length
            let panelLen = (isVertical ? outerPanel.height : outerPanel.width)
            let priorLen = panelLen - nodeLen 
            let nodeSpace = priorLen / (count-1)
            let space = nodeSpace - nodeLen
            return space
        }
    }

    func setAspectFromType() {

        switch nodeType {

        case .none, .node, .tog, .tap:

            aspect(1.0 * CGFloat(columns),
                   1.0 * CGFloat(columns))

        case .val  : aspect(1.0, 4.0)
        case .xy   : aspect(4.0, 4.0)
        case .xyz  : aspect(4.5, 4.0)
        case .seg  : aspect(1.0, 4.0)
        case .peer : aspect(6.0, 3.0)
        case .arch : aspect(6.0, 6.0)
        case .hand : aspect(4.0, 3.5)
        }
        func aspect(_ lo: CGFloat,_ hi: CGFloat  ) {
            aspectSz = isVertical || nodeType == .peer
            ? CGSize(width: lo, height: hi)
            : CGSize(width: hi, height: lo)
        }
    }

    // changed by type
    var thumbRadius: Double { Double(Layout.radius - 1) }

    func thumbDiameter(_ runway: Runway) -> Double {
        switch runway {
        case .runX,.runY,.runZ : return thumbRadius
        default       : return thumbRadius * 2
        }
    }

    func runLength(_ runway: Runway) -> Double {
        let inner = innerPanel(runway)
        let diameter = thumbDiameter(runway)
        let run: Double
        switch runway {
        case .runX,.runT : run = inner.width  - diameter
        case .runY,.runZ : run = inner.height - diameter
        default          : run = (isVertical
                                  ? inner.height - diameter
                                  : inner.width  - diameter)
        }
        return run
    }

    var runwayXY: CGPoint {
        let innerXY = innerPanel(.runXY)
        return CGPoint(x: innerXY.height - thumbDiameter(.runXY),
                       y: innerXY.width  - thumbDiameter(.runXY))
    }
    var runwayXYZ: CGPoint {
        let innerXYZ = innerPanel(.runXYZ)
        return CGPoint(x: innerXYZ.height - thumbDiameter(.runXY),
                       y: innerXYZ.width  - thumbDiameter(.runXY))
    }

    var inner: CGSize {
        
        let result =  aspectSz * Layout.diameter
        return result
    }

    func innerPanel(_ runway: Runway) -> CGSize {
        let d = Layout.diameter
        switch runway {
        case .runX,.runT : return CGSize(width: d * 2.5, height: d * 0.5)
        case .runY,.runZ : return CGSize(width: d * 0.5, height: d * 2.5)
        case .runXYZ     : return CGSize(width: d * 3.0, height: d * 3.0)
        default          : return aspectSz * d
        }
    }

    var outerPanel: CGSize {

        let pad = Layout.padding2
        let dia = Layout.diameter2

        switch nodeType {

        case .val, .seg:

            return inner + (isVertical
                            ? CGSize(width: pad, height: dia)
                            : CGSize(width: dia, height: pad))
        case .xyz, .xy:

            return inner

        case .hand, .peer, .arch: // header is always on top

            return inner + CGSize(width: pad, height: dia)

        case .none, .node, .tog, .tap:

            if columns > 1 {
                let rowi = (branchVm.nodeVms.count + 1) / columns
                let rows = min(CGFloat(rowi), maxNodes)
                let cols = CGFloat(columns)
                return CGSize(width:  dia * cols,
                              height: dia * rows) + pad
            } else {
                let length = dia * min(count,maxNodes)
                let width  = isVertical ? dia : length
                let height = isVertical ? length : dia
                return CGSize(width: width, height: height)
            }
        }
    }

    var titleSize: CGSize {
        if isVertical ||
            (menuTrees.count == 1 &&
             (menuTrees.first?.nodeType == .xy ||
              menuTrees.first?.nodeType == .peer)) {

            // title is always on top
            return CGSize(width:  inner.width,
                          height: Layout.diameter - 8)
        } else {
            return CGSize(width:  Layout.diameter - 8,
                          height: Layout.diameter - 8)
        }
    }
    func normalizeTouch(xy: SIMD2<Double>) -> SIMD3<Double>{
        let length = runLength(.runXY)
        let xMax = (inner.width  - thumbRadius)
        let yMax = (inner.height - thumbRadius)
        let xRange = thumbRadius...xMax
        let yRange = thumbRadius...yMax
        let xClamp = xy.x.clamped(to: xRange)
        let yClamp = xy.y.clamped(to: yRange)
        let xNormal = (xClamp - thumbRadius) / length
        let yNormal = (yClamp - thumbRadius) / length
        return SIMD3<Double>(xNormal, 1-yNormal, 0)
    }
    func normalizeTouch(xyz: SIMD3<Double>) -> SIMD3<Double> {
        let length = runLength(.runXYZ)
        let xMax = (inner.width  - thumbRadius)
        let yMax = (inner.height - thumbRadius)
        let zMax = (inner.height - thumbRadius)
        let xRange = thumbRadius...xMax
        let yRange = thumbRadius...yMax
        let zRange = thumbRadius...zMax
        let xClamp = xyz.x.clamped(to: xRange)
        let yClamp = xyz.y.clamped(to: yRange)
        let zClamp = xyz.z.clamped(to: zRange)
        let xNormal = (xClamp - thumbRadius) / length
        let yNormal = (yClamp - thumbRadius) / length
        let zNormal = (zClamp - thumbRadius) / length
        return SIMD3<Double>(xNormal, 1-yNormal, zNormal)
    }

    /// convert touch coordinates to 0...1
    func normalizeTouch(v: Double) -> Double {
        let length = runLength(.runXY)
        if isVertical {
            let yMax = (inner.height - thumbRadius)
            let yClamp = v.clamped(to: thumbRadius...yMax)
            let yNormal = (yClamp - thumbRadius) / length
            return 1.0 - yNormal // invert so that 0 is on bottom
        } else {
            let xMax = (inner.width  - thumbRadius)
            let xClamp = v.clamped(to: thumbRadius...xMax)
            let xNormal = (xClamp - thumbRadius) / length
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
        let result = CGRect(x: center.x - outerPanel.width/2,
                            y: center.y - outerPanel.height/2,
                            width: outerPanel.width,
                            height: outerPanel.height)
        return result
    }
}
