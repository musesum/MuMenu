//  created by musesum on 7/30/22.

import SwiftUI

class StatusVm: ObservableObject {
    static var shared = StatusVm()

    var before = [NodeVm]()
    var after  = [NodeVm]()
    var beforeStr: String {
        var line = ""
        var delim = "• "
        for vm in before {
            if let leafVm = vm as? LeafVm {
                line += delim + (leafVm.leafProto?.leafTitle() ?? "??")
            } else {
                line += delim + vm.node.title
            }
            delim = " • "
        }
        return line
    }
    var afterStr: String {
        var line = ""
        var delim = "• "
        for vm in after {
            if let leafVm = vm as? LeafVm {
                line += delim + (leafVm.leafProto?.leafTitle() ?? "??")
            } else {
                line += delim + vm.node.title
            }
            delim = " • "
        }
        return line
    }
    func update(before: [NodeVm], after: [NodeVm]) {
        self.before = before
        self.after = after
        show = true
    }
    func update(leafVm: LeafVm) {
        if let beforeVm = before.last as? LeafVm {
            if beforeVm == leafVm {
                show = show
            }
        } else if let afterVm = after.last as? LeafVm {
            if afterVm == leafVm {
                show = show
            }
        }
    }
    @Published var show = false

    static func statusLine(_ tog: Toggle) {
        switch tog {
            case .on:  shared.show = true
            case .off: shared.show = false
        }
    }
}
