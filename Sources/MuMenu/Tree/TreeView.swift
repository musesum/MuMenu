// created by musesum 10/29/21.
import SwiftUI

/// hierarchical menu of horizontal or vertical branches
struct TreeView: View {

    @ObservedObject var treeVm: TreeVm

    var corner: CornerOps { treeVm.rootVm.corner }

    var body: some View {

        ZStack(alignment: corner.alignment) {

            // TreeCanopyView(treeVm: treeVm)

            if treeVm.isVertical {
                HStack(alignment: corner.vAlign)  {
                    ForEach(corner.right
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
            } else {
                VStack(alignment: corner.hAlign) {
                    ForEach(corner.lower
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
            }
        }
        .offset(treeVm.treeOffset)
    }
}

/// hierarchical menu of horizontal or vertical branches
struct TreeCanopyView: View {

    @ObservedObject var treeVm: TreeVm

    let cornerRadius = Layout.radius + Layout.padding
    var treeSize: CGSize { treeVm.treeBounds.size }

    var body: some View {

        Rectangle()
            .background(.thinMaterial)
            .cornerRadius(cornerRadius)
            .opacity(0.01)
            .frame(width: treeSize.width, height: treeSize.height)
    }
}

