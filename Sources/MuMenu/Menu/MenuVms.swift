//  created by musesum on 12/1/22.

import MuFlo
import MuPeer
import MuVision

public struct MenuVms {

    public var menuVms = [MenuVm]()
    
    public init(_ root˚: Flo, _ archiveVm: ArchiveVm, _ peers: Peers) {

        Icon.altBundles.append(MuMenu.bundle)
        Icon.altBundles.append(MuVision.bundle) //??

        let menuTree = MenuTree(root˚)

        #if os(visionOS)
        let floNames = ["canvas", "plato", "cell", "more"]
        let cornerLeft  = Corner(menuTree, .vertical, .left,  [.upper, .left])
        let cornerRight = Corner(menuTree, .vertical, .right, [.upper, .right])
        if let menu = MenuVm([cornerLeft], floNames, archiveVm, peers) { menuVms.append(menu) }
        if let menu = MenuVm([cornerRight],floNames, archiveVm, peers) { menuVms.append(menu) }
        #else
        let floNames = ["canvas", "plato", "cell", "camera", "more"]
        let cornerLeft  = Corner(menuTree, .vertical, .left,  [.lower, .left])
        let cornerRight = Corner(menuTree, .vertical, .right, [.lower, .right])
        if let menu = MenuVm([cornerLeft], floNames, archiveVm, peers) { menuVms.append(menu) }
        if let menu = MenuVm([cornerRight],floNames, archiveVm, peers) { menuVms.append(menu) }
        #endif
    }
}
