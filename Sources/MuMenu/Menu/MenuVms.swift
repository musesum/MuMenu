//  created by musesum on 12/1/22.

import MuFlo

struct MenuVms {

    var menuVms = [MenuVm]()
    
    init(_ root: Flo) {
        let rootNode = MuFloNode(root)
        
        menuVms.append(
            MenuVm([.lower, .left],
                   [(rootNode, .vertical),
                    (rootNode, .horizontal)]))
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
