//  created by musesum on 12/1/22.

import MuFlo

public struct MenuVms {

    public var menuVms = [MenuVm]()
    
    public init(_ root: Flo) {
        let rootNode = FloNode(root)
        
        menuVms.append(
            MenuVm([.lower, .left],
                   [(rootNode, .vertical)]))

//            MenuVm([.lower, .left],
//                   [(rootNode, .vertical),
//                    (rootNode, .horizontal)]))
//        
//        menuVms.append(
//            MenuVm([.lower, .right],
//                   [(rootNode, .vertical),
//                    (rootNode, .horizontal)]))
//        
//        menuVms.append(
//            MenuVm([.upper, .left],
//                   [(rootNode, .vertical),
//                    (rootNode, .horizontal)]))
//        
//        menuVms.append(
//            MenuVm([.upper, .right],
//                   [(rootNode, .vertical),
//                    (rootNode, .horizontal)]))
    }
}
