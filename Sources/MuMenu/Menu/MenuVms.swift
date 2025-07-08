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

        #if false // os(visionOS)
        let rootNW = RootVm([.N,.W], archiveVm, peers) // North West corner
        let rootNE = RootVm([.N,.E], archiveVm, peers) // North East corner
        menuVms.append(MenuVm(rootNW, [.N,.W,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootNW, [.N,.W,.H], hMenu, rootTree)) // horiz
        menuVms.append(MenuVm(rootNE, [.N,.E,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootNE, [.N,.E,.H], hMenu, rootTree)) // horiz
        #elseif os(visionOS)
        let rootSW = RootVm([.S,.W], archiveVm, peers) // North West corner
        let rootSE = RootVm([.S,.E], archiveVm, peers) // North East corner
        menuVms.append(MenuVm(rootSW, [.S,.W,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSW, [.S,.W,.H], hMenu, rootTree)) // horiz
        menuVms.append(MenuVm(rootSE, [.S,.E,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSE, [.S,.E,.H], hMenu, rootTree)) // horiz
        #else
        let rootSW = RootVm([.S,.W], archiveVm, peers) // South West corner
        let rootSE = RootVm([.S,.E], archiveVm, peers) // South East corner
        menuVms.append(MenuVm(rootSW, [.S,.W,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSW, [.S,.W,.H], hMenu, rootTree)) // horiz
        menuVms.append(MenuVm(rootSE, [.S,.E,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSE, [.S,.E,.H], hMenu, rootTree)) // horiz
        #endif
    }
}
