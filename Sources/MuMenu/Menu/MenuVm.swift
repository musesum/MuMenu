//  created by musesum on 6/4/22.

import SwiftUI
import MuFlo
import MuPeer
import MuVision

open class MenuVm {
    var id = Visitor.nextId()
    public var rootVm: RootVm
    public var floNames: [String] = []

    /// one or two menus emanating from a corner
    ///
    ///  - parameters:
    ///     - corners: vertical and/or horizonal menu(s)
    ///
    ///   - note: assuming maximum of two menues from corner
    ///     with complementary horizontal/vertical axis
    ///
    public init?(_ corners: [Corner], _ floNames: [String], _ archiveVm: ArchiveVm,_ peers: Peers) {

        guard corners.count > 0 else { print("corners < 1") ; return nil }
        self.floNames = floNames
        var treeVms = [TreeVm]()

        // both veritical and horizontal menu will share the same root
        self.rootVm = RootVm(corners.first!.cornerOp, archiveVm, peers)

        for corner in corners {
            let cornerTreeVm = TreeVm(rootVm, corner)
            var menuTrees = [MenuTree]()

            for floName in floNames {
                if let menuTree = updateMenuTree(corner, floName) {
                    menuTrees.append(menuTree)

                }
            }
            updateBranches(menuTrees, cornerTreeVm)
        }
        func updateBranches(_ menuTrees: [MenuTree],
                            _ treeVm: TreeVm) {

            let branchVm = BranchVm(menuTrees: menuTrees,
                                    treeVm: treeVm,
                                    prevNodeVm: nil)

            treeVm.addBranchVms([branchVm])
            treeVms.append(treeVm)

            rootVm.updateTreeVms(treeVm)
            rootVm.showSoloTree(false)
            rootVm.startAutoHide(false)
        }
    }
    func updateMenuTree(_ corner: Corner,
                        _ floName: String) -> MenuTree? {

        let cornerRoot˚ = corner.rootMenu.flo

        if let namedFlo = cornerRoot˚.findPath(floName) {

            let menuTree = makeMenuTree(from: namedFlo,
                                        parentTree: corner.rootMenu)

            updateSpotTree(corner, floName, menuTree)
            return menuTree
        }
        return nil
    }

    func updateSpotTree(_ corner: Corner,
                        _ floName: String,
                        _ menuTreeRoot: MenuTree?) {

        guard let menuTreeRoot else { return }

        let root˚ = corner.rootMenu.flo
        let chiral = corner.chiral

        // two separate spotTrees for left and right sides
        if let spotTree = root˚.findPath(chiral.name + ".spot") {

            //DebugLog("𐂷 found: \(chiral.name) {\n\(spotTree.scriptFull)\n}\n")
            mergeSpotMenu(chiral, spotTree, menuTreeRoot)

        } else if let spotTree = makeSpotTree(menuTreeRoot) {

            //DebugLog { P("𐂷 make:  \(chiral.name) {\n\(spotTree.scriptFull)\n}\n") }
            mergeSpotMenu(chiral, spotTree, menuTreeRoot)

        } else {
           err("no spotTree")
        }

        func err(_ msg: String) {
            //.... PrintLog("𐂷 MenuVm::updateSpotTree err: \(msg)")
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
    func makeMenuTree(from: Flo,
                      parentTree: MenuTree) -> MenuTree {
        let menuTree = MenuTree(from, parentTree: parentTree)
        for child in from.children {
            if child.name.first != "_" {
                makeMenuTree(from: child, parentTree: menuTree)
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



