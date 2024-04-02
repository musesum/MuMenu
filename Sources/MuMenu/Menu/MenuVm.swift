//  created by musesum on 6/4/22.

import SwiftUI
import MuFlo
import MuHand

public struct CornerFlo {

    let floNode: FloNode
    let axis: Axis
    let menu: String
    let model: String
    let key: String

    public init (_ floNode: FloNode,
                 _ axis: Axis,
                 _ menu: String,
                 _ model: String,
                 _ key: String) {

        self.floNode = floNode
        self.axis    = axis
        self.menu    = menu
        self.model   = model
        self.key     = key
    }
}

open class MenuVm {
    let id: Int = Visitor.nextId()
    public var rootVm: RootVm
    public init(_ rootVm: RootVm) {
        self.rootVm = rootVm
    }


    /// one or two menus emanating from a corner
    ///
    ///  - parameters:
    ///     - corner: placement of root node
    ///     - rootAxis: (flo root node, axis)
    ///
    ///   - note: assuming maximum of two menues from corner,
    ///     with different axis
    ///

    public init(_ cornerOp: CornerOp,
                _ cornerFlos: [CornerFlo]) {

        self.rootVm = RootVm(cornerOp)
        var skyTreeVms = [TreeVm]()

        // for (root˚,axis) in floAxis {
        for cornerFlo in cornerFlos {

            let cornerItem = CornerItem(cornerOp, cornerFlo.axis, cornerFlo.key)
            let skyTreeVm = TreeVm(rootVm, cornerItem)
            let skyNodes = MenuVm.skyNodes(cornerOp, cornerFlo)

            let skyBranchVm = BranchVm(nodes: skyNodes,
                                         treeVm: skyTreeVm,
                                         prevNodeVm: nil)

            skyTreeVm.addBranchVms([skyBranchVm])
            skyTreeVms.append(skyTreeVm)
        }

        rootVm.updateTreeVms(skyTreeVms)
        rootVm.showSoloTree(false)
        Icon.altBundles.append(MuMenu.bundle)
    }

    static func skyNodes(_ corner: CornerOp,
                         _ cornerFlo: CornerFlo) -> [FloNode] {

        let rootFlo = cornerFlo.floNode.modelFlo
        Icon.altBundles.append(MuHand.bundle)
        if let menuFlo = rootFlo.findPath(cornerFlo.menu),
           let modelFlo = rootFlo.findPath(cornerFlo.model) {

            let floNode = parseFloNode(modelFlo, cornerFlo.floNode)
            mergeFloNode(menuFlo, floNode)
            return cornerFlo.floNode.children.first?.children ?? []

        } else {

            for child in rootFlo.children {
                parseFloNode(child, cornerFlo.floNode)
            }
            return cornerFlo.floNode.children
        }
    }

    /// recursively parse flo hierachy
    @discardableResult
    static func parseFloNode(_ flo: Flo,
                             _ parentNode: FloNode) -> FloNode {

        let node = FloNode(flo, parent: parentNode)
        for child in flo.children {
            if child.name.first != "_" {
                parseFloNode(child, node)
            }
        }
        return node
    }

    /// merge menu.view with with model
    static func mergeFloNode(_ viewFlo: Flo,
                             _ parentNode: FloNode) {

        for child in viewFlo.children {

            if let nodeFlo = findFloNode(child) {

                let icon = nodeFlo.makeFloIcon(child)
                nodeFlo.icon = icon
                nodeFlo.viewFlo = viewFlo

                if nodeFlo.children.count == 1,
                   let grandChild = nodeFlo.children.first,
                   grandChild.nodeType.isControl {

                    grandChild.icon = icon
                }
                mergeFloNode(child, nodeFlo)
            }
        }
        func findFloNode(_ flo: Flo) -> FloNode? {
            if parentNode.title == flo.name {
                return parentNode
            }
            for childNode in parentNode.children {
                if childNode.title == flo.name {
                    return childNode
                }
            }
            return nil
        }
    }

}
extension MenuVm: Hashable {

    public static func == (lhs: MenuVm, rhs: MenuVm) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

}



