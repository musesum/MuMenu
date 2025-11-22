//  created by musesum on 12/1/22.

import MuFlo
import MuPeers
import MuVision
import MuHands
import Foundation


public typealias MenuVms = [MenuVm]
@MainActor
public struct Menus {
    static var bundles = [Bundle]()
    public var menuVms = MenuVms()
    
    public init(_ root˚: Flo,
                _ archiveVm: ArchiveVm,
                _ phase: HandsPhase,
                _ peers: Peers) {

        Menus.bundles.append(MuMenu.bundle)
        Menus.bundles.append(MuVision.bundle)

        let rootTree = MenuTree(root˚)
        #if os(visionOS)
        let vNames: [String] = ["canvas"  , "brush" ,
                                "plato"   , "cell"  ,
                                "archive" , "music" ,
                                "tape"    , "more"  ]
#else
        let vNames: [String] = ["canvas"  , "brush" ,
                                "plato"   , "cell"  ,
                                "archive" , "music" ,
                                "camera"  , "mic"   ,
                                "tape"    , "more"  ]
        #endif

        let rootSW = RootVm([.S,.W,.L], menuVms, archiveVm, phase, peers) // SW Left
        let rootSE = RootVm([.S,.E,.R], menuVms, archiveVm, phase, peers) // SE Right
        let swv = MenuBranch([.S,.W,.V], vNames) //SW Verti
        let sev = MenuBranch([.S,.E,.V], vNames) //SE Verti
        #if true // only vertical menu
        menuVms.append(MenuVm(rootSW, [swv], rootTree, columns: 2))
        menuVms.append(MenuVm(rootSE, [sev], rootTree, columns: 2))
        #else // both vertical and horizontal menu
        let hNames: [String] = ["chat"]
        let swh = MenuBranch([.S,.W,.H], hNames) //SW Horiz
        let seh = MenuBranch([.S,.E,.H], hNames) //SE Horiz
        menuVms.append(MenuVm(rootSW, [swv,swh], rootTree))
        menuVms.append(MenuVm(rootSE, [sev,seh], rootTree))
        #endif
    }
}
