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
        let rootNW = RootVm(.NW, archiveVm, peers) // North West corner
        let rootNE = RootVm(.NE, archiveVm, peers) // North East corner
        menuVms.append(MenuVm(rootNW, .NWV, vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootNW, .NWH, hMenu, rootTree)) // horiz
        menuVms.append(MenuVm(rootNE, .NEV, vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootNE, .NEH, hMenu, rootTree)) // horiz
        #else
        let rootSW = RootVm(.SW, archiveVm, peers) // South West corner
        let rootSE = RootVm(.SE, archiveVm, peers) // South East corner
        menuVms.append(MenuVm(rootSW, .SWV, vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSW, .SWH, hMenu, rootTree)) // horiz
        menuVms.append(MenuVm(rootSE, .SEV, vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSE, .SEH, hMenu, rootTree)) // horiz
        #endif
    }
}
