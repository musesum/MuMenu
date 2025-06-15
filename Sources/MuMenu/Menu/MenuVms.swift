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
        let vertiMenu = ["canvas", "plato", "cell", "camera"]
        let horiMenu = ["more.bonjour", "more.archive", "more.search"]
        #if os(visionOS)
        let UL = CornerOp([.upper, .left])
        let UR = CornerOp([.upper, .right])
        let rootLL = RootVm(UL, archiveVm, peers)
        let rootLR = RootVm(UR, archiveVm, peers)

        // vertical menu
        let VUL = Corner(menuTree, .vertical, UL)
        let VUR = Corner(menuTree, .vertical, UR)
        menuVms.append(MenuVm(rootLL, VUL, vertiMenu))
        menuVms.append(MenuVm(rootLR, VUR, vertiMenu))

        //..... horizonal menu
        let HUL = Corner(menuTree, .horizontal, UL)
        let HUR = Corner(menuTree, .horizontal, UR)
        menuVms.append(MenuVm(rootLL, HUL, horiMenu))
        menuVms.append(MenuVm(rootLR, HUR, horiMenu))

        #elseif true // dual vertical/horizontal menu
        // 
        let DLV = MenuOp("DLV")
        let DRV = MenuOp("DRV")
        let rootDLV = RootVm(DLV, archiveVm, peers)
        let rootDRV = RootVm(DRV, archiveVm, peers)

        let trunkDLV = Trunk(menuTree, DLV)
        let trunkDRV = Trunk(menuTree, DRV)
        menuVms.append(MenuVm(rootDLV, trunkDLV, vertiMenu))
        menuVms.append(MenuVm(rootDRV, trunkDRV, vertiMenu))

        //..... horizonal menu
        let DLH = MenuOp("DLH")
        let DRH = MenuOp("DRH")
        let rootDLH = RootVm(DLH, archiveVm, peers)
        let rootDRH = RootVm(DRH, archiveVm, peers)

        let trunkDLH = Trunk(menuTree, DLH)
        let trunkDRH = Trunk(menuTree, DRH)
        menuVms.append(MenuVm(rootDLH, trunkDLH, horiMenu))
        menuVms.append(MenuVm(rootDRH, trunkDRH, horiMenu))

        #else
        // vertical menu
        let DLV = MenuOp("DLV")
        let DRV = MenuOp("DRV")
        menuVms.append(MenuVm(DLV), Trunk(menuTree, DLV), vertiMenu)
        menuVms.append(MenuVm(DRV), Trunk(menuTree, DRV), vertiMenu)

        //..... horizonal menu
        let DLH = MenuOp("DLH")
        let DRH = MenuOp("DRH")
        menuVms.append(MenuVm(DLH), Trunk(menuTree, DLH),horiMenu)
        menuVms.append(MenuVm(DRH), Trunk(menuTree, DRH),horiMenu)


        #endif
    }
}

