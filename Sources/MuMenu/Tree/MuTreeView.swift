// Created by warren 10/29/21.
import SwiftUI

/// hierarchical menu of horizontal or vertical branches
struct MuTreeView: View {

    @ObservedObject var treeVm: MuTreeVm

    var corner: CornerOps { treeVm.rootVm.corner }

    var body: some View {

        ZStack(alignment: corner.alignment) {

            MuTreeCanopyView(treeVm: treeVm)

            if treeVm.isVertical {
                HStack(alignment: corner.vAlign)  {
                    ForEach(corner.right
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        MuBranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
            } else {
                VStack(alignment: corner.hAlign) {
                    ForEach(corner.lower
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        MuBranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
            }
        }
        .offset(treeVm.treeOffset)
    }
}

/// hierarchical menu of horizontal or vertical branches
struct MuTreeCanopyView: View {

    @ObservedObject var treeVm: MuTreeVm

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

