//  Created by warren on 7/30/22.

import SwiftUI

class MuStatusVm: ObservableObject {
    static var shared = MuStatusVm()

    var before = [MuNodeVm]()
    var after  = [MuNodeVm]()
    var beforeStr: String {
        var line = ""
        var delim = "• "
        for vm in before {
            if let leafVm = vm as? MuLeafVm {
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
            if let leafVm = vm as? MuLeafVm {
                line += delim + (leafVm.leafProto?.leafTitle() ?? "??")
            } else {
                line += delim + vm.node.title
            }
            delim = " • "
        }
        return line
    }
    func update(before: [MuNodeVm], after: [MuNodeVm]) {
        self.before = before
        self.after = after
        show = true
    }
    func update(leafVm: MuLeafVm) {
        if let beforeVm = before.last as? MuLeafVm {
            if beforeVm == leafVm {
                show = show
            }
        } else if let afterVm = after.last as? MuLeafVm {
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

struct MuStatusView: View {

    @ObservedObject var statusVm = MuStatusVm.shared

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.black)
                .opacity(0.5)
            HStack {
                Text(statusVm.beforeStr)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .foregroundColor(.white)
                Text(statusVm.afterStr)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .foregroundColor(.gray)
            }
        }
        .opacity(statusVm.show ? 1 : 0)
    }
}
