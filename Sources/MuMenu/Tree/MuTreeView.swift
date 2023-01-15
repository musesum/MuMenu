// Created by warren 10/29/21.
import SwiftUI

/// hierarchical menu of horizontal or vertical branches
struct MuTreeView: View {

    @ObservedObject var treeVm: MuTreeVm

    var corner: MuCorner { treeVm.rootVm.corner }
    var treeSize: CGSize { treeVm.treeBounds.size }

    var body: some View {

        ZStack(alignment: corner.alignment) {
            if treeVm.isVertical {

                HStack(alignment: corner.vAlign)  {
                    ForEach(corner.contains(.right)
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        MuBranchView(branchVm: $0,
                                     spotlight: $0 == treeVm.branchSpotVm)
                        .zIndex($0.zindex)
                    }
                }

            } else {
                VStack(alignment: corner.hAlign) {
                    ForEach(corner.contains(.lower)
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        MuBranchView(branchVm: $0,
                                     spotlight: $0 == treeVm.branchSpotVm)
                        .zIndex($0.zindex)
                    }
                }
            }
            MuTreeCanopyView(treeVm: treeVm)
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
            .background(.red)
            .cornerRadius(cornerRadius)
            .opacity(0.2)
            .frame(width: treeSize.width, height: treeSize.height)
            .zIndex(0)
    }
}

