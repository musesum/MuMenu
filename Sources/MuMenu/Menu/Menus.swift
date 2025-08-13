//  created by musesum on 12/1/22.

import MuFlo
import MuPeers
import MuVision
import MuHands
@MainActor
public struct Menus {

    public var menuVms = [MenuVm]()
    
    public init(_ root˚: Flo,
                _ archiveVm: ArchiveVm,
                _ phase: HandsPhase,
                _ peers: Peers) {

        Icon.altBundles.append(MuMenu.bundle)
        Icon.altBundles.append(MuVision.bundle)

        let rootTree = MenuTree(root˚)
        #if os(visionOS)
        let vNames: [String] = ["canvas", "plato", "cell", "more"]
        #else
        let vNames: [String] = ["canvas", "plato", "cell", "camera", "more"]
        #endif

        let rootSW = RootVm([.S,.W,.L], archiveVm, phase, peers) // SW Left
        let rootSE = RootVm([.S,.E,.R], archiveVm, phase, peers) // SE Right
        let swv = MenuBranch([.S,.W,.V], vNames) //SW Verti
        let sev = MenuBranch([.S,.E,.V], vNames) //SE Verti
        #if false // only vertical menu
        menuVms.append(MenuVm(rootSW, [swv], rootTree))
        menuVms.append(MenuVm(rootSE, [sev], rootTree))
        #else // both vertical and horizontal menu
        let hNames: [String] = ["tape","archive", "chat"]
        let swh = MenuBranch([.S,.W,.H], hNames) //SW Horiz
        let seh = MenuBranch([.S,.E,.H], hNames) //SE Horiz
        menuVms.append(MenuVm(rootSW, [swv,swh], rootTree))
        menuVms.append(MenuVm(rootSE, [sev,seh], rootTree))
        #endif
    }
}
