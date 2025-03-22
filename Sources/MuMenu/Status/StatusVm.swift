//  created by musesum on 7/30/22.

import SwiftUI
import MuFlo

@Observable class StatusVm: Identifiable {

    static var shared = StatusVm()

    var before = [NodeVm]()
    var after  = [NodeVm]()
    var beforeStr: String {
        var line = ""
        var delim = "• "
        for vm in before {
            if let leafVm = vm as? LeafVm {
                line += delim + (leafVm.leafTitle() )
            } else {
                line += delim + vm.menuTree.flo.name
            }
            delim = " • "
        }
        return line
    }
    var show = false

    var afterStr: String {
        var line = ""
        var delim = "• "
        for vm in after {
            if let leafVm = vm as? LeafVm {
                line += delim + (leafVm.leafTitle() )
            } else {
                line += delim + vm.menuTree.flo.name
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

    static func statusLine(_ tog: OnOff) {
        switch tog {
            case .on:  shared.show = true
            case .off: shared.show = false
        }
    }
}
