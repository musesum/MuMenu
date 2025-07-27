//  created by musesum on 12/1/22.

import MuFlo
import MuPeers
import MuVision
import MuHands
@MainActor
public struct MenuHands {

    public var menuVms = [MenuVm]()
    
    public init(_ root˚: Flo,
                _ archiveVm: ArchiveVm,
                _ handsPhase: HandsPhase,
                _ peers: Peers) {

        Icon.altBundles.append(MuMenu.bundle)
        Icon.altBundles.append(MuVision.bundle)

        let rootTree = MenuTree(root˚)
        let vMenu: [String] = ["canvas", "plato", "cell", "camera", "more"]
        let hMenu: [String] = ["chat"]

        #if false // os(visionOS)
        let rootNW = RootVm([.N,.W], archiveVm, handsPhase, peers) // North West corner
        let rootNE = RootVm([.N,.E], archiveVm, handsPhase, peers) // North East corner
        menuVms.append(MenuVm(rootNW, [.N,.W,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootNE, [.N,.E,.V], vMenu, rootTree)) // verti
        // menuVms.append(MenuVm(rootNW, [.N,.W,.H], hMenu, rootTree)) // horiz
        // menuVms.append(MenuVm(rootNE, [.N,.E,.H], hMenu, rootTree)) // horiz
        #elseif os(visionOS)
        let rootSW = RootVm([.S,.W,.L], archiveVm, handsPhase, peers) // North West corner
        let rootSE = RootVm([.S,.E,.R], archiveVm, handsPhase, peers) // North East corner
        menuVms.append(MenuVm(rootSW, [.S,.W,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSE, [.S,.E,.V], vMenu, rootTree)) // verti
        // menuVms.append(MenuVm(rootSW, [.S,.W,.H], hMenu, rootTree)) // horiz
        // menuVms.append(MenuVm(rootSE, [.S,.E,.H], hMenu, rootTree)) // horiz
        #else
        let rootSW = RootVm([.S,.W,.L], archiveVm, handsPhase, peers) // SouthWest
        let rootSE = RootVm([.S,.E,.R], archiveVm, handsPhase, peers) // SouthEast
        menuVms.append(MenuVm(rootSW, [.S,.W,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSE, [.S,.E,.V], vMenu, rootTree)) // verti
        menuVms.append(MenuVm(rootSW, [.S,.W,.H], hMenu, rootTree)) // horiz
        menuVms.append(MenuVm(rootSE, [.S,.E,.H], hMenu, rootTree)) // horiz
        #endif
    }
}
