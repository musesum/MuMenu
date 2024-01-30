//  created by musesum on 6/4/22.

import SwiftUI
import MuFlo

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
    public init(_ corner: CornerOp,
                _ rootAxis: [(FloNode, Axis)]) {

        self.rootVm = RootVm(corner)
        var skyTreeVms = [TreeVm]()

        for (rootNode,axis) in rootAxis {
            let cornerAxis = CornerAxis(corner,axis)
            let skyTreeVm = TreeVm(rootVm, cornerAxis)
            let skyNodes = MenuVm.skyNodes(rootNode, corner)

            let skyBranchVm = BranchVm(nodes: skyNodes,
                                         treeVm: skyTreeVm,
                                         prevNodeVm: nil)

            skyTreeVm.addBranchVms([skyBranchVm])
            skyTreeVms.append(skyTreeVm)
        }

        rootVm.updateTreeVms(skyTreeVms)
        Icon.altBundle = MuMenu.bundle
    }

    static func skyNodes(_ rootNode: FloNode,
                         _ corner: CornerOp) -> [FloNode] {

        let rootFlo = rootNode.modelFlo

        if let menuFlo = rootFlo.findPath("menu"),
           let modelFlo = rootFlo.findPath("model") {

            let cornerStr = corner.str()

            if let cornerFlo = menuFlo.findPath(cornerStr) {

                let model = parseFloNode(modelFlo, rootNode)
                mergeFloNode(cornerFlo, model)

            } else {
                // parse everything together
                parseFloNode(menuFlo, rootNode)
            }
            return rootNode.children.first?.children ?? []

        } else {

            for child in rootFlo.children {
                parseFloNode(child, rootNode)
            }
            return rootNode.children
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



