// created by musesum 10/29/21.
import SwiftUI

/// hierarchical menu of horizontal or vertical branches
struct TreeView: View {

    @ObservedObject var treeVm: TreeVm

    var menuType: MenuType { treeVm.rootVm.cornerType }
    var treeOpacity: CGFloat { treeVm.treeState == .showTree ? 1 : 0 }
    var treeAnimation: CGFloat { treeVm.treeState == .showTree ? 0.25 : 1.0 }

    var body: some View {

        ZStack(alignment: menuType.alignment) {

            //TreeCanopyView(treeVm: treeVm)

            if treeVm.menuType.vertical {
                HStack(alignment: menuType.vAlign)  {
                    ForEach(menuType.east
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
                .opacity(treeOpacity)
            } else {
                VStack(alignment: menuType.hAlign) {
                    ForEach(menuType.south
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                        .zIndex($0.zindex)
                    }
                }
                .opacity(treeOpacity)
            }
        }
        .animation(Animate(treeAnimation), value: treeOpacity)
        .offset(treeVm.treeOffset)
    }
}

/// hierarchical menu of horizontal or vertical branches
struct TreeCanopyView: View {

    @ObservedObject var treeVm: TreeVm

    let cornerRadius = Menu.radius + Menu.padding
    var treeSize: CGSize { treeVm.treeBounds.size }
    var canopyAlpha: CGFloat { treeVm.treeState == .canopy ? 0.5 : 0 }

    var body: some View {

        Rectangle()
            .background(.thinMaterial)
            .cornerRadius(cornerRadius)
            .opacity(canopyAlpha)
            .frame(width: treeSize.width, height: treeSize.height)
    }
}

