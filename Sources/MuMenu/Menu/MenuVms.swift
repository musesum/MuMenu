//  created by musesum on 12/1/22.

import MuFlo
import MuVision

public struct MenuVms {

    public var menuVms = [MenuVm]()
    
    public init(_ root˚: Flo) {
        
        Icon.altBundles.append(MuMenu.bundle)
        Icon.altBundles.append(MuVision.bundle) //??

        let menuTree = MenuTree(root˚)
#if os(visionOS)
        if let vm = MenuVm([Corner(menuTree, .vertical, .left, [.upper, .left ])]) {
            menuVms.append(vm)
        }
        if let vm = MenuVm([Corner(menuTree, .vertical, .right, [.upper, .right])]) {
            menuVms.append(vm)
        }

#else
        if let vm = MenuVm([Corner(menuTree, .vertical, .left,  [.lower, .left ]),
                          // Corner(menuTree, .horizontal, "hands", [.lower, .left ])
                         ]) {
            menuVms.append(vm)
        }


        if let vm = MenuVm([Corner(menuTree, .vertical, .right, [.lower, .right]),
                            //Corner(menuTree, .horizontal, "hands", [.lower, .right])
                           ]) {
            menuVms.append(vm)
        }

        #endif

    }
}
