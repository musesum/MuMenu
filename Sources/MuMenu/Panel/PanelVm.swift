//  created by musesum on 12/20/21.

import SwiftUI
import MuFlo

@MainActor
public class PanelVm {

    let branchVm: BranchVm
    var menuTrees: [MenuTree]
    var nodeType: NodeType
    var menuType: MenuType
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
        self.nodeType = (count > 1 ? .node : menuTrees.first?.nodeType ?? .node)
        self.menuType = treeVm.menuType
        setAspectFromType()
    }
    var spacing: CGFloat {
        if count <= maxNodes {
            return 0
        } else {
            // the last node always is in the same place on a panel
            // so, calculate the spacing of the prior nodes
            let nodeLen = Menu.diameter2 // node length
            let panelLen = (branchVm.treeVm.menuType.vertical
                            ? outerPanel.height
                            : outerPanel.width)
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

        case .val  : (menuType.vertical
                      ? aspect(1.0, 4.0)
                      : aspect(4.0, 1.0))

        case .xy     : aspect(4.0, 4.0)
        case .xyz    : aspect(4.5, 4.0)
        case .seg    : aspect(1.0, 4.0)
        case .peer   : aspect(6.0, 6.0)
        case .search : aspect(6.0, 3.0)
        case .arch   : aspect(6.0, 6.0)
        case .hand   : aspect(4.0, 3.5)
        }
        func aspect(_ lo: CGFloat,_ hi: CGFloat  ) {
            aspectSz = (menuType.vertical || nodeType == .peer)
            ? CGSize(width: lo, height: hi)
            : CGSize(width: hi, height: lo)
        }
    }

    var thumbRadius: Double { Double(Menu.radius - 1) }

    func thumbDiameter(_ type: LeafRunwayType) -> Double {
        switch type {
        case .runX,.runY,.runZ : return thumbRadius
        default                : return thumbRadius * 2
        }
    }

    func runLength(_ runwayType: LeafRunwayType) -> Double {
        let inner = innerPanel(runwayType)
        let diameter = thumbDiameter(runwayType)
        let length: Double
        switch runwayType {
        case .runX,.runT : length = inner.width  - diameter
        case .runY,.runZ : length = inner.height - diameter
        default          : length = (menuType.vertical
                                  ? inner.height - diameter
                                  : inner.width  - diameter)
        }
        return length
    }

    var runwayXY: CGPoint {
        let innerXY = innerPanel(.runXY)
        return CGPoint(x: innerXY.height - thumbDiameter(.runXY),
                       y: innerXY.width  - thumbDiameter(.runXY))
    }

    private var innerSize: CGSize {
        let result =  aspectSz * Menu.diameter
        return result
    }

    func innerPanel(_ runwayType: LeafRunwayType) -> CGSize {
        let d = Menu.diameter
        switch runwayType {

        case .none       : return aspectSz * d

        case .runX,.runT : return CGSize(width: d * 2.5, height: d * 0.5)
        case .runY,.runZ : return CGSize(width: d * 0.5, height: d * 2.5)

        case .runVal     : return (menuType.vertical
                                   ? CGSize(width: d * 1.0, height: d * 4.0)
                                   : CGSize(width: d * 1.0, height: d * 4.0))

        default          : return CGSize(width: d * 3.0, height: d * 3.0)
        }
        
    }

    var outerPanel: CGSize {

        let pad = Menu.padding2
        let dia = Menu.diameter2

        switch nodeType {

        case .val, .seg, .xyz, .xy:

            return innerSize + pad

        case .hand, .peer, .arch, .search: // header is always on top

            return innerSize + CGSize(width: pad, height: dia)

        case .none, .node, .tog, .tap:

            if columns > 1 {
                let rowi = (branchVm.nodeVms.count + 1) / columns
                let rows = min(CGFloat(rowi), maxNodes)
                let cols = CGFloat(columns)
                return CGSize(width:  dia * cols,
                              height: dia * rows) + pad
            } else {
                let length = dia * min(count,maxNodes)
                let vertical = menuType.vertical
                let width  = vertical ? dia : length
                let height = vertical ? length : dia
                return CGSize(width: width, height: height)
            }
        }
    }

    var titleSize: CGSize {
        if menuType.vertical ||
            (menuTrees.count == 1 &&
             (menuTrees.first?.nodeType == .xy ||
              menuTrees.first?.nodeType == .peer)) {

            // title is always on top
            return CGSize(width:  innerSize.width,
                          height: Menu.diameter - 8)
        } else {
            return CGSize(width:  Menu.diameter - 8,
                          height: Menu.diameter - 8)
        }
    }

    func updatePanelBounds(_ bounds: CGRect) -> CGRect {
        var result = bounds
        if menuType.vertical {
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
