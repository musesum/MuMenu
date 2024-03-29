//  created by musesum on 12/1/22.

import MuFlo
import MuVision

public struct MenuVms {

    public var menuVms = [MenuVm]()
    
    public init(_ root: Flo) {
        let floNode = FloNode(root)
#if os(visionOS)
        menuVms.append(
            MenuVm([.upper, .left ],
                   [CornerFlo(floNode, .vertical, "model_", "model"),
                   ]))

        menuVms.append(
            MenuVm([.upper, .right],
                   [CornerFlo(floNode, .vertical,"model_", "model"),
                   ]))

        #else
        print(floNode.modelFlo.scriptFull)
        menuVms.append(
            MenuVm([.lower, .left ],
                   [CornerFlo(floNode, .vertical, "model_", "model"),
                    //CornerFlo(floNode, .horizontal, "hands_", "hands")
                   ]))

        menuVms.append(
            MenuVm([.lower, .right],
                   [CornerFlo(floNode, .vertical, "model_", "model"),
                    //CornerFlo(floNode, .horizontal, "hands_", "hands")
                    ]))
        #endif


//        menuVms.append(
//            MenuVm([.lower, .right],
//                   [(rootNode, .vertical),
//                    (rootNode, .horizontal)])
//        
//        menuVms.append(
//            MenuVm([.upper, .left],
//                   [(rootNode, .vertical),
//                    (rootNode, .horizontal)])
//        
//        menuVms.append(
//            MenuVm([.upper, .right],
//                   [(rootNode, .vertical),
//                    (rootNode, .horizontal)])

    }
}
