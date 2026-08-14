//  created by musesum on 12/1/22.

import MuFlo
#if !os(watchOS)
import MuPeers
import MuVision
import MuHands
#endif
import Foundation


public typealias MenuVms = [MenuVm]
@MainActor
public struct Menus {
    static var bundles = [Bundle]()
    public var menuVms = MenuVms()
    
    public init(_ root˚: Flo,
                _ archiveVm: ArchiveVm,
                _ phase: HandsPhase,
                startHidden: Bool = false) {

        Menus.bundles.append(MuMenu.bundle)
        #if !os(watchOS)
        Menus.bundles.append(MuVision.bundle)
        #endif

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
        let WNames: [String] = ["canvas", "brush", "plato", "cell","camera"]
        let ENames: [String] = ["music", "mic", "tape", "archive", "more" ]
        let WLogo = "eye"
        let ELogo = "ear"
        let rootSW = RootVm([.S,.W,.L], WLogo, menuVms, archiveVm, phase) // SW Left
        let rootSE = RootVm([.S,.E,.R], ELogo, menuVms, archiveVm, phase) // SE Right
        let swv = MenuBranch([.S,.W,.V], WNames) //SW Verti
        let sev = MenuBranch([.S,.E,.V], ENames) //SE Verti
        #if !os(watchOS) // graph leaf needs WebKit
        let NNames: [String] = ["graph"]
        let NLogo = "point.3.connected.trianglepath.dotted"
        let rootNE = RootVm([.N,.E,.R], NLogo, menuVms, archiveVm, phase) // NE Right
        let nev = MenuBranch([.N,.E,.V], NNames) //NE Verti
        #endif
        #if true // only vertical menu
        if let rootTree {
            menuVms.append(MenuVm(rootSW, [swv], rootTree, startHidden: startHidden))
            menuVms.append(MenuVm(rootSE, [sev], rootTree, startHidden: startHidden))
            #if !os(watchOS)
            menuVms.append(MenuVm(rootNE, [nev], rootTree, startHidden: startHidden))
            #endif
        }
        #else // both vertical and horizontal menu
        let hNames: [String] = ["chat"]
        let swh = MenuBranch([.S,.W,.H], hNames) //SW Horiz
        let seh = MenuBranch([.S,.E,.H], hNames) //SE Horiz
        menuVms.append(MenuVm(rootSW, [swv,swh], rootTree))
        menuVms.append(MenuVm(rootSE, [sev,seh], rootTree))
        #endif
        // RootVm captured an empty snapshot above; backfill after both menuVms exist
        for menuVm in menuVms { menuVm.rootVm.menuVms = menuVms }
    }
}
