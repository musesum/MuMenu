//  created by musesum on 6/4/22.

import SwiftUI
import MuFlo
import MuPeers
import MuVision

open class MenuVm {

    var id = Visitor.nextId()

    public var rootVm: RootVm

    public init(_ rootVm: RootVm,
                _ trunk: Trunk,
                _ floNames: [String]) {

        // both veritical and horizontal menu will share the same root
        self.rootVm = rootVm

        var menuTrees = [MenuTree]()
        for floName in floNames {
            if let menuTree = makeMenuTree(trunk, floName) {
                menuTrees.append(menuTree)
            }
        }
        // updateBranches
        let treeVm = TreeVm(rootVm, trunk)
        let branchVm = BranchVm(menuTrees: menuTrees, treeVm: treeVm)
        treeVm.addBranchVm(branchVm)
        rootVm.addTreeVm(treeVm)
        rootVm.showSoloTree()
        rootVm.startAutoHide()
    }
    func makeMenuTree(_ trunk: Trunk,
                      _ floName: String) -> MenuTree? {

        let cornerRoot˚ = trunk.rootMenu.flo

        if let namedFlo = cornerRoot˚.findPath(floName) {
            let menuTree = makeMenuTree(from: namedFlo, parentTree: trunk.rootMenu)
            updateSpotTree(trunk, floName, menuTree)
            return menuTree
        }
        return nil
    }

    func updateSpotTree(_ trunk: Trunk,
                        _ floName: String,
                        _ menuTree: MenuTree?) {

        guard let menuTree else { return }

        let root˚ = trunk.rootMenu.flo

        // two separate spotTrees for left and right sides
        if let spotTree = root˚.findPath(trunk.menuOp.key + ".spot") {

            //DebugLog("𐂷 found: \(chiral.name) {\n\(spotTree.scriptFull)\n}\n")
            mergeSpotMenu(trunk.menuOp, spotTree, menuTree)

        } else if let spotTree = makeSpotTree(menuTree, trunk) {

            //DebugLog { P("𐂷 make:  \(chiral.name) {\n\(spotTree.scriptFull)\n}\n") }
            mergeSpotMenu(trunk.menuOp, spotTree, menuTree)

        } else {
           err("no spotTree")
        }

        func err(_ msg: String) {
            //... PrintLog("𐂷 MenuVm::updateSpotTree err: \(msg)")
        }

        func makeSpotTree(_ menuTree: MenuTree, _ trunk: Trunk) -> Flo? {

            guard let menuFlo = root˚.findPath("menu") else { return nil }

            let chiralFlo = Flo(trunk.menuOp.key, parent: root˚)
            let spotFlo = Flo("spot", parent: chiralFlo)

            /// make `on 0` expression and decorate shadow-clone of
            let spotExpress = Exprs(spotFlo, [("on", 0)])
            for menuChild in menuFlo.children {
                if menuChild.name.first == "_" { continue }
                _ = Flo(decorate: menuChild, parent: spotFlo, exprs: spotExpress)
            }
            NoDebugLog { P("\(chiralFlo.name) { \n\(chiralFlo.scriptFull) \n} ") }
            mergeSpotMenu(trunk.menuOp, spotFlo, menuTree)
            return spotFlo
        }
}

    /// recursively parse flo hierachy
    @discardableResult
    func makeMenuTree(from: Flo, parentTree: MenuTree) -> MenuTree {
        let menuTree = MenuTree(from, parentTree: parentTree)
        for child in from.children {
            if child.name.first != "_" {
                makeMenuTree(from: child, parentTree: menuTree)
            }
        }
        return menuTree
    }

    /// merge menu.view with with model
    func mergeSpotMenu(_ menuOp   : MenuOp,
                       _ spotFlo  : Flo,
                       _ menuTree : MenuTree) {

        for spotChild in spotFlo.children {
            if let menuTree = findMenuNode(spotChild, menuTree) {
                menuTree.chiralSpot[menuOp.chiral] = spotFlo
                mergeSpotMenu(menuOp, spotChild, menuTree)
            }
        }
    }


    func findMenuNode(_ menuFlo: Flo,
                      _ menuTree: MenuTree) -> MenuTree? {

        if menuTree.flo.name == menuFlo.name {
            return menuTree
        }
        for child in menuTree.children {
            if let menuTree = findMenuNode(menuFlo, child) {
                return menuTree
            }
        }
        return nil
    }

}
extension MenuVm: Hashable {

    public static func == (lhs: MenuVm, rhs: MenuVm) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

}



