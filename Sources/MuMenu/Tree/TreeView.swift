// created by musesum 10/29/21.
import SwiftUI

/// hierarchical menu of horizontal or vertical branches
struct TreeView: View {

    @ObservedObject var treeVm: TreeVm

    var menuOp: MenuOp { treeVm.rootVm.menuOp }
    var canopyOpacity: CGFloat { treeVm.showTree == .canopy ? 0.5 : 0 }
    var treeOpacity: CGFloat { treeVm.showTree == .show ? 1 : 0 }

    var body: some View {

        ZStack(alignment: menuOp.alignment) {

            //..... TreeCanopyView(treeVm: treeVm) .opacity(canopyOpacity)

            if treeVm.trunk.menuOp.vertical {
                HStack(alignment: menuOp.vAlign)  {
                    ForEach(menuOp.right
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
                .opacity(treeOpacity)
            } else {
                VStack(alignment: menuOp.hAlign) {
                    ForEach(menuOp.down
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
                .opacity(treeOpacity)
            }
        }
        .animation(Animate(treeVm.interval), value: canopyOpacity)
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
            .opacity(0.33)
            .frame(width: treeSize.width, height: treeSize.height)
    }
}

