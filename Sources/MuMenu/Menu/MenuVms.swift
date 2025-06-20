//  created by musesum on 12/1/22.

import MuFlo
import MuPeers
import MuVision

public struct MenuVms {

    public var menuVms = [MenuVm]()
    
    public init(_ root˚: Flo, _ archiveVm: ArchiveVm, _ peers: Peers) {

        Icon.altBundles.append(MuMenu.bundle)
        Icon.altBundles.append(MuVision.bundle)

        let rootTree = MenuTree(root˚)
        let vMenu = ["canvas", "plato", "cell", "camera"]
        let hMenu = ["more.bonjour", "more.archive", "more.search"]

        #if os(visionOS)
        let rootUL = RootVm(.UL, archiveVm, peers) // up left
        let rootUR = RootVm(.UR, archiveVm, peers) // up right
        menuVms.append(MenuVm(rootUL, .ULV, vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootUL, .ULH, hMenu, rootTree)) // horiz
        menuVms.append(MenuVm(rootUR, .URV, vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootUR, .URH, hMenu, rootTree)) // horiz
        #else
        let rootDL = RootVm(.DL, archiveVm, peers) // down left
        let rootDR = RootVm(.DR, archiveVm, peers) // down right
        menuVms.append(MenuVm(rootDL, .DLV, vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootDL, .DLH, hMenu, rootTree)) // horiz
        menuVms.append(MenuVm(rootDR, .DRV, vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootDR, .DRH, hMenu, rootTree)) // horiz
        #endif
    }
}
