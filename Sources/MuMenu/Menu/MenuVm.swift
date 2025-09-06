//  created by musesum on 6/4/22.

import SwiftUI
import MuFlo
import MuPeers
import MuVision

@MainActor
open class MenuVm {

    let id = Visitor.nextId()
    let rootMenu: MenuTree

    public var rootVm: RootVm
    public var cornerType: MenuType
    public var isShowing: Bool {
        for treeVm in rootVm.treeVms {
            if treeVm.showTree.state.hidden == false {
                return true
            }
        }
        return false
    }

    public init(_ rootVm    : RootVm ,
                _ branches  : [MenuBranch],
                _ rootMenu  : MenuTree) {

        // both veritical and horizontal menu will share the same root
        self.rootVm = rootVm
        self.cornerType = rootVm.cornerType
        self.rootMenu = rootMenu

        for branch in branches {
            var menuTrees = [MenuTree]()
            for name in branch.names {
                if let menuTree = makeMenuTree(name) {
                    menuTrees.append(menuTree)
                }
            }
            let treeVm = TreeVm(rootVm, branch.type)
            let branchVm = BranchVm(menuTrees: menuTrees, treeVm: treeVm)
            treeVm.addBranchVm(branchVm)
            rootVm.addTreeVm(treeVm)
        }
        // updateBranches
        rootVm.showFirstTree()
        rootVm.startAutoFades()
    }
    public init(_ rootVm    : RootVm ,
                _ menuType  : MenuType,
                _ floNames  : [String],
                _ rootMenu  : MenuTree) {

        // both veritical and horizontal menu will share the same root
        self.rootVm = rootVm
        self.rootMenu = rootMenu
        self.cornerType = rootVm.cornerType

        var menuTrees = [MenuTree]()
        for floName in floNames {
            if let menuTree = makeMenuTree(floName) {
                menuTrees.append(menuTree)
            }
        }
        // updateBranches
        let treeVm = TreeVm(rootVm, menuType)
        let branchVm = BranchVm(menuTrees: menuTrees, treeVm: treeVm)
        treeVm.addBranchVm(branchVm)
        rootVm.addTreeVm(treeVm)
        rootVm.showFirstTree()
        rootVm.startAutoFades()
    }
    func makeMenuTree(_ floName: String) -> MenuTree? {

        let cornerRoot˚ = rootMenu.flo

        if let namedFlo = cornerRoot˚.findPath(floName) {
            let menuTree = makeMenuTree(from: namedFlo,
                                        parentTree: rootMenu)
            updateSpotTree(floName, menuTree)
            return menuTree
        }
        return nil
    }

    func updateSpotTree(_ floName: String,
                        _ menuTree: MenuTree?) {

        guard let menuTree else { return }

        let root˚ = rootMenu.flo

        // two separate spotTrees for left and right sides
        if let spotTree = root˚.findPath(cornerType.key + ".spot") {

            //DebugLog("𐂷 found: \(chiral.name) {\n\(spotTree.scriptFull)\n}\n")
            mergeSpotMenu(cornerType, spotTree, menuTree)

        } else if let spotTree = makeSpotTree(menuTree) {

            //DebugLog { P("𐂷 make:  \(chiral.name) {\n\(spotTree.scriptFull)\n}\n") }
            mergeSpotMenu(cornerType, spotTree, menuTree)

        } else {
           err("no spotTree")
        }

        func err(_ msg: String) {
            //... PrintLog("𐂷 MenuVm::updateSpotTree err: \(msg)")
        }

        func makeSpotTree(_ menuTree: MenuTree) -> Flo? {

            guard let menuFlo = root˚.findPath("menu") else { return nil }

            let chiralFlo = Flo(cornerType.key, parent: root˚)
            let spotFlo = Flo("spot", parent: chiralFlo)

            /// make `on 0` expression and decorate shadow-clone of
            let spotExpress = Exprs(spotFlo, [("on", 0)])
            for menuChild in menuFlo.children {
                if menuChild.name.first == "_" { continue }
                _ = Flo(decorate: menuChild, parent: spotFlo, exprs: spotExpress)
            }
            NoDebugLog { P("\(chiralFlo.name) { \n\(chiralFlo.scriptFull) \n} ") }
            mergeSpotMenu(cornerType, spotFlo, menuTree)
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
    func mergeSpotMenu(_ menuType   : MenuType,
                       _ spotFlo  : Flo,
                       _ menuTree : MenuTree) {

        for spotChild in spotFlo.children {
            if let menuTree = findMenuNode(spotChild, menuTree) {
                menuTree.chiralSpot[menuType.chiral] = spotFlo
                mergeSpotMenu(menuType, spotChild, menuTree)
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
extension MenuVm: @MainActor Hashable {

    public static func == (lhs: MenuVm, rhs: MenuVm) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

}



