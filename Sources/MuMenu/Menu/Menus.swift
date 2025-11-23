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

        let WNames: [String] = ["canvas", "brush", "plato", "cell","camera"]
        let ENames: [String] = ["music", "mic", "tape", "archive", "more" ]
        let WLogo = "eye"
        let ELogo = "ear"
        #endif

        let rootSW = RootVm([.S,.W,.L], WLogo, menuVms, archiveVm, phase, peers) // SW Left
        let rootSE = RootVm([.S,.E,.R], ELogo, menuVms, archiveVm, phase, peers) // SE Right
        let swv = MenuBranch([.S,.W,.V], WNames) //SW Verti
        let sev = MenuBranch([.S,.E,.V], ENames) //SE Verti
        #if true // only vertical menu
        menuVms.append(MenuVm(rootSW, [swv], rootTree))
        menuVms.append(MenuVm(rootSE, [sev], rootTree))
        #else // both vertical and horizontal menu
        let hNames: [String] = ["chat"]
        let swh = MenuBranch([.S,.W,.H], hNames) //SW Horiz
        let seh = MenuBranch([.S,.E,.H], hNames) //SE Horiz
        menuVms.append(MenuVm(rootSW, [swv,swh], rootTree))
        menuVms.append(MenuVm(rootSE, [sev,seh], rootTree))
        #endif
    }
}
