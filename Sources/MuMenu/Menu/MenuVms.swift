//  created by musesum on 12/1/22.

import MuFlo
import MuPeers
import MuVision

public struct MenuVms {

    public var menuVms = [MenuVm]()
    
    public init(_ root˚: Flo, _ archiveVm: ArchiveVm, _ peers: Peers) {

        Icon.altBundles.append(MuMenu.bundle)
        Icon.altBundles.append(MuVision.bundle)

        let menuTree = MenuTree(root˚)

        #if os(visionOS)
        let floNames = ["canvas", "plato", "cell", "more"]
        //let UL = CornerOp([.upper, .left])
        //let UR = CornerOp([.upper, .right])
        let VUL = Corner(menuTree, .vertical, .left,  [.upper, .left])
        let VUR = Corner(menuTree, .vertical, .right, [.upper, .right])
        if let m = MenuVm([VUL], floNames, archiveVm, peers) { menuVms.append(m) }
        if let m = MenuVm([VUR], floNames, archiveVm, peers) { menuVms.append(m) }
        #elseif true // legacy
        let floNames = ["canvas", "plato", "cell", "camera", "more"]
        let cornerLeft  = Corner(menuTree, .vertical, .left,  [.lower, .left])
        let cornerRight = Corner(menuTree, .vertical, .right, [.lower, .right])
        if let m = MenuVm([cornerLeft], floNames, archiveVm, peers) { menuVms.append(m) }
        if let m = MenuVm([cornerRight],floNames, archiveVm, peers) { menuVms.append(m) }
        #else // dual vertical/horizontal corner version -- some issues
        let LL = CornerOp([.lower, .left])
        let LR = CornerOp([.lower, .right])
        let rootLL = RootVm(LL, archiveVm, peers)
        let rootLR = RootVm(LR, archiveVm, peers)

        let vNames = ["canvas", "plato", "cell", "camera", "more"]
        let VLL = Corner(menuTree, .vertical, .left,  LL)
        let VLR = Corner(menuTree, .vertical, .right, LR)
        menuVms.append(MenuVm(rootLL, VLL, vNames))
        menuVms.append(MenuVm(rootLR, VLR, vNames))

        let hNames = ["search"]
        let HLR = Corner(menuTree, .horizontal, .right, LR)
        let HLL = Corner(menuTree, .horizontal, .left,  LL)
        menuVms.append(MenuVm(rootLL, HLL, hNames))
        menuVms.append(MenuVm(rootLR, HLR, hNames))

        #endif
    }
}

