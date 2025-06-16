// created by musesum 10/29/21.
import SwiftUI

/// hierarchical menu of horizontal or vertical branches
struct TreeView: View {

    @ObservedObject var treeVm: TreeVm

    var menuType: MenuType { treeVm.rootVm.cornerType }
    var canopyAlpha: CGFloat { treeVm.showTree == .canopy ? 0.5 : 0 }
    var treeOpacity: CGFloat { treeVm.showTree == .show ? 1 : 0 }

    var body: some View {

        ZStack(alignment: menuType.alignment) {

            // TreeCanopyView(treeVm: treeVm) .opacity(canopyOpacity) //.....

            if treeVm.menuType.vertical {
                HStack(alignment: menuType.vAlign)  {
                    ForEach(menuType.right
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
                .opacity(treeOpacity)
            } else {
                VStack(alignment: menuType.hAlign) {
                    ForEach(menuType.down
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
                .opacity(treeOpacity)
            }
        }
        .animation(Animate(treeVm.interval), value: canopyAlpha)
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

