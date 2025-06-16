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
        let rootUL = RootVm(.UL, archiveVm, peers)
        let rootUR = RootVm(.UR, archiveVm, peers)
        menuVms.append(MenuVm(rootUL, .ULV, vMenu, rootTree))
        menuVms.append(MenuVm(rootUL, .ULH, hMenu, rootTree))
        menuVms.append(MenuVm(rootUR, .URV, vMenu, rootTree))
        menuVms.append(MenuVm(rootUR, .URH, hMenu, rootTree))

        #else
        let rootDL = RootVm(.DL, archiveVm, peers)
        let rootDR = RootVm(.DR, archiveVm, peers)
        menuVms.append(MenuVm(rootDL, .DLV, vMenu, rootTree))
        menuVms.append(MenuVm(rootDL, .DLH, hMenu, rootTree))
        menuVms.append(MenuVm(rootDR, .DRV, vMenu, rootTree))
        menuVms.append(MenuVm(rootDR, .DRH, hMenu, rootTree))
        #endif
    }
}

