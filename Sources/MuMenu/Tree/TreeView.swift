// created by musesum 10/29/21.
import SwiftUI

/// hierarchical menu of horizontal or vertical branches
struct TreeView: View {

    @ObservedObject var treeVm: TreeVm
    @ObservedObject var showTree: ShowTime

    var menuType: MenuType { treeVm.rootVm.cornerType }
    var showOpacity: CGFloat { treeVm.showTree.opacity }
    var showAnimation: Animation { treeVm.showTree.animation }
    
    init(treeVm: TreeVm) {
        self.treeVm = treeVm
        self.showTree = treeVm.showTree
    }

    var body: some View {

        ZStack(alignment: menuType.alignment) {

            //TreeCanopyView(treeVm: treeVm)

            if treeVm.menuType.vertical {
                HStack(alignment: menuType.vAlign)  {
                    ForEach(menuType.east
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                    }
                }
            } else {
                VStack(alignment: menuType.hAlign) {
                    ForEach(menuType.south
                            ? treeVm.branchVms.reversed()
                            : treeVm.branchVms) {

                        BranchView(branchVm: $0)
                    }
                }
            }
        }
        .opacity(showOpacity)
        .animation(showAnimation, value: showOpacity)
        .offset(treeVm.treeOffset)
    }
}

/// hierarchical menu of horizontal or vertical branches
struct TreeCanopyView: View {

    @ObservedObject var treeVm: TreeVm

    let cornerRadius = Menu.radius + Menu.padding
    var treeSize: CGSize { treeVm.treeBounds.size }
    var canopyAlpha: CGFloat { 0 } //treeVm.showTime.state == .showing ? 0.01 : 0 }

    var body: some View {

        Rectangle()
            .background(.clear)
            .cornerRadius(cornerRadius)
            .opacity(canopyAlpha)
            .frame(width: treeSize.width, height: treeSize.height)
    }
}

