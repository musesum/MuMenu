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
                   [CornerFlo(floNode, .vertical, "model_", "model", "left"),
                   ]))

        menuVms.append(
            MenuVm([.upper, .right],
                   [CornerFlo(floNode, .vertical,"model_", "model", "right"),
                   ]))

        #else
        print(floNode.modelFlo.scriptFull)
        menuVms.append(
            MenuVm([.lower, .left ],
                   [CornerFlo(floNode, .vertical, "model_", "model", "left"),
                    //CornerFlo(floNode, .horizontal, "hands_", "hands")
                   ]))

        menuVms.append(
            MenuVm([.lower, .right],
                   [CornerFlo(floNode, .vertical, "model_", "model", "right"),
                    //CornerFlo(floNode, .horizontal, "hands_", "hands")
                    ]))
        #endif

    }
}
