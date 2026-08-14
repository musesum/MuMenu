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
    var codeRows: Int /// `{}` rows stacked under a value control

    init(branchVm: BranchVm,
         menuTrees: [MenuTree],
         treeVm: TreeVm,
         columns: Int) {

        self.branchVm = branchVm
        self.menuTrees = menuTrees
        self.columns = columns
        self.count = CGFloat(menuTrees.count)
        // `{}` code rows ride under the value control instead of turning the
        // branch into a chooser, so the control keeps its own panel shape
        self.codeRows = menuTrees.filter { $0.isCodeRow }.count
        let controls = menuTrees.filter { !$0.isCodeRow }
        self.nodeType = (codeRows > 0 && controls.count == 1
                         ? controls[0].nodeType
                         : count > 1 ? .node : menuTrees.first?.nodeType ?? .node)
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

        case .val  :
            #if os(watchOS)
            // watchOS uses a square panel for val so the menu-mode tap target
            // is large enough; orientation no longer affects the layout.
            aspect(3.0, 3.0)
            #else
            menuType.vertical ? aspect(1.0, 4.0) : aspect(4.0, 1.0)
            #endif

        case .xy     :
            #if os(watchOS)
            // watchOS XY row layout is runY (d·0.5) + 4 + runXY (d·3) =
            // ~3.96·d wide PLUS HStack spacing + bezel stroke padding.
            // Total vertical = row1 (~d·0.6) + row2 (d·3) = ~3.6·d.
            // 4.0·d clips on small screen — give visible margin on both
            // axes so the panel doesn't touch the slot edges.
            aspect(4.7, 4.7)
            #else
            aspect(4.0, 4.0)
            #endif
        case .xyz    :
            #if os(watchOS)
            // watchOS XYZ row layout is runY (d·0.5) + 4 + runXY (d·3) +
            // 4 + runZ (d·0.5) = ~4.62·d wide. Height same as XY.
            // Earlier 5.0·d still clipped — bump to 5.5·d wide and 4.7·d
            // tall to match XY's safe margin.
            aspect(5.5, 4.7)
            #else
            aspect(4.5, 4.0)
            #endif
        case .xyzw   :
            // xyz plus a bottom runW row (d·0.5 + spacing) under the pad
            #if os(watchOS)
            aspect(5.5, 5.4)
            #else
            aspect(4.5, 4.75)
            #endif
        case .vf     :
            // vf rides the xyzw frame: grayed x row + y|scope|z row + w row
            #if os(watchOS)
            aspect(5.5, 5.4)
            #else
            aspect(4.5, 4.75)
            #endif
        case .seg    : aspect(1.0, 4.0)
        case .peer   : aspect(6.0, 6.0)
        case .search : aspect(6.0, 3.0)
        case .arch   : aspect(6.0, 6.0)
        case .hand   : aspect(4.0, 3.5)
        case .graph  : aspect(17.0, 12.0) // 680·480; LeafGraphVm rewrites this on resize
        case .code   : aspect(14.0, 12.0) // 560·480 editor page plus bottom bar
        case .midi   :
            // phone portrait: fit beside the 48pt trunk column inside 402pt
            Menu.phonePortrait ? aspect(8.0, 8.5) : aspect(9.0, 8.0) // 11×8 grid + legend + source row
        case .sequencer :
            // starts two rows tall; LeafSequencerVm grows this per row count
            Menu.phonePortrait ? aspect(8.5, 3.0) : aspect(11.0, 3.0)
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
        case .runX,.runY,.runZ,.runW : return thumbRadius
        default                : return thumbRadius * 2
        }
    }

    func runLength(_ runwayType: LeafRunwayType) -> Double {
        let inner = innerPanel(runwayType)
        let diameter = thumbDiameter(runwayType)
        let length: Double
        switch runwayType {
        case .runX,.runT,.runW : length = inner.width  - diameter
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

    /// one node row per `{}` code row, along the branch's stacking axis
    private var codeRowsSize: CGSize {
        guard codeRows > 0 else { return .zero }
        let len = Menu.diameter2 * CGFloat(codeRows)
        return menuType.vertical
        ? CGSize(width: 0, height: len)
        : CGSize(width: len, height: 0)
    }

    func innerPanel(_ runwayType: LeafRunwayType) -> CGSize {
        let d = Menu.diameter
        switch runwayType {

        case .none       : return aspectSz * d

        case .runX,.runT,.runW : return CGSize(width: d * 2.5, height: d * 0.5)
        case .runY,.runZ : return CGSize(width: d * 0.5, height: d * 2.5)

        case .runVal     :
            #if os(watchOS)
            return CGSize(width: d * 3.0, height: d * 3.0)
            #else
            return CGSize(width: d * 1.0, height: d * 4.0)
            #endif

        default          : return CGSize(width: d * 3.0, height: d * 3.0)
        }
        
    }

    var outerPanel: CGSize {

        let pad = Menu.padding2
        let dia = Menu.diameter2

        switch nodeType {

        case .val, .seg, .xyz, .xyzw, .vf, .xy, .graph, .code, .midi, .sequencer:

            // .graph and .code carry their own header inside innerSize
            return innerSize + pad + codeRowsSize

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
