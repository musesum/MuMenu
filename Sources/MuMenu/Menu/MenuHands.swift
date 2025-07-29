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
                _ phase: HandsPhase,
                _ peers: Peers) {

        Icon.altBundles.append(MuMenu.bundle)
        Icon.altBundles.append(MuVision.bundle)

        let rootTree = MenuTree(root˚)
        let vNames: [String] = ["canvas", "plato", "cell", "camera", "more"]
        let hNames: [String] = ["chat"]

        let rootSW = RootVm([.S,.W,.L], archiveVm, phase, peers) // SW Left
        let rootSE = RootVm([.S,.E,.R], archiveVm, phase, peers) // SE Right
        let swv = MenuBranch([.S,.W,.V], vNames) //SW Verti
        let swh = MenuBranch([.S,.W,.H], hNames) //SW Horiz
        let sev = MenuBranch([.S,.E,.V], vNames) //SE Verti
        let seh = MenuBranch([.S,.E,.H], hNames) //SE Horiz
        menuVms.append(MenuVm(rootSW, [swv,swh], rootTree))
        menuVms.append(MenuVm(rootSE, [sev,seh], rootTree))
    }
}
