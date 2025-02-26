//  created by musesum on 6/4/22.

import SwiftUI
import MuFlo
import MuVision

open class MenuVm {

    let id: Int = Visitor.nextId()

    public var rootVm: RootVm
    public var menuTree: MenuTree? // top node of menu tree


    /// one or two menus emanating from a corner
    ///
    ///  - parameters:
    ///     - corners: vertical and/or horizonal menu(s)
    ///
    ///   - note: assuming maximum of two menues from corner
    ///     with complementary horizontal/vertical axis
    ///
    public init?(_ corners: [Corner]) {

        guard corners.count > 0 else { print("corners < 1") ; return nil }

        var treeVms = [TreeVm]()

        // both veritical and horizontal menu will share the same root
        self.rootVm = RootVm(corners.first!.cornerOp)

        // for (root˚,axis) in floAxis {
        for corner in corners {

            let treeVm = TreeVm(rootVm, corner)
            updateMenuTree(corner)
            updateSpotTree(corner)

           guard let menuTree else { continue }

            let branchVm = BranchVm(menuTrees: menuTree.children,
                                    treeVm: treeVm,
                                    prevNodeVm: nil)

            treeVm.addBranchVms([branchVm])
            treeVms.append(treeVm)

            rootVm.updateTreeVms(treeVms)
            rootVm.showSoloTree(false)
            rootVm.startAutoHide(false)
        }
    }
    func updateMenuTree(_ corner: Corner) {
        if menuTree != nil { return }
        let root˚ = corner.rootMenu.model˚

        if let menuFlo = root˚.findPath("menu"),
           let modelFlo = root˚.findPath("model") {

            let menuTree = makeMenuTree(from: modelFlo, corner.rootMenu)
            self.menuTree = menuTree
            mergeMenuFlo(menuFlo, menuTree)
        }
    }

    func updateSpotTree(_ corner: Corner) {

        guard let menuTree else { return }

        let root˚ = corner.rootMenu.model˚
        let chiral = corner.chiral

        // two separate spotTrees for left and right sides
        if let spotTree = root˚.findPath(chiral.name + ".spot") {

            //DebugLog("𐂷 found: \(chiral.name) {\n\(spotTree.scriptFull)\n}\n")
            mergeSpotMenu(chiral, spotTree, menuTree)

        } else if let spotTree = makeSpotTree(menuTree) {

            //DebugLog { P("𐂷 make:  \(chiral.name) {\n\(spotTree.scriptFull)\n}\n") }
            mergeSpotMenu(chiral, spotTree, menuTree)

        } else {
           err("no spotTree")
        }

        func err(_ msg: String) {
            PrintLog("𐂷 MenuVm::updateSpotTree err: \(msg)")
        }

        func makeSpotTree(_ menuTree: MenuTree) -> Flo? {

            guard let menuFlo = root˚.findPath("menu") else { return nil }

            let chiralFlo = Flo(chiral.name, parent: root˚)
            let spotFlo = Flo("spot", parent: chiralFlo)

            /// make `on 0` expression and decorate shadow-clone of
            let spotExpress = Exprs(spotFlo, [("on", 0)])
            for menuChild in menuFlo.children {
                if menuChild.name.first == "_" { continue }
                _ = Flo(decorate: menuChild, parent: spotFlo, exprs: spotExpress)
            }
            NoDebugLog { P("\(chiralFlo.name) { \n\(chiralFlo.scriptFull) \n} ") }
            mergeSpotMenu(chiral, spotFlo, menuTree)
            return spotFlo
        }
}

    /// recursively parse flo hierachy
    @discardableResult
    func makeMenuTree(from modelFlo : Flo,
                      _ menuParent  : MenuTree) -> MenuTree {

        let menuTree = MenuTree(modelFlo, parent: menuParent)
        for modelChild in modelFlo.children {
            if modelChild.name.first != "_" {
                makeMenuTree(from: modelChild, menuTree)
            }
        }
        return menuTree
    }

    /// merge menu.view with with model
    func mergeSpotMenu(_ chiral   : Chiral,
                       _ spotFlo  : Flo,
                       _ menuTree : MenuTree) {

        for spotChild in spotFlo.children {
            if let menuTree = findMenuNode(spotChild, menuTree) {
                menuTree.chiralSpot[chiral] = spotFlo
                mergeSpotMenu(chiral, spotChild, menuTree)
            }
        }
    }


    func findMenuNode(_ menuFlo: Flo,
                      _ menuTree: MenuTree) -> MenuTree? {

        if menuTree.title == menuFlo.name {
            return menuTree
        }
        for child in menuTree.children {
            if let menuTree = findMenuNode(menuFlo, child) {
                return menuTree
            }
        }
        return nil
    }

    /// merge menu.view with with model
    func mergeMenuFlo(_ menuFlo  : Flo,
                      _ menuTree : MenuTree) {

        for child in menuFlo.children {

            if let menuTree = findMenuNode(child, menuTree) {

                let icon = menuTree.makeFloIcon(child)
                menuTree.icon = icon
                menuTree.menu˚ = child

                if menuTree.children.count == 1,
                   let grandChild = menuTree.children.first,
                   grandChild.nodeType.isControl {

                    grandChild.icon = icon
                }
                mergeMenuFlo(child, menuTree)
            }
        }
    }

}
extension MenuVm: Hashable {

    public static func == (lhs: MenuVm, rhs: MenuVm) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

}



