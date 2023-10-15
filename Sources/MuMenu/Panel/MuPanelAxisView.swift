// created by musesum on 10/7/21.


import SwiftUI

struct MuPanelAxisView<Content: View>: View {

    let panelVm: MuPanelVm
    let content: () -> Content
    var spacing: CGFloat { panelVm.spacing }

    init(_ panel: MuPanelVm, @ViewBuilder content: @escaping () -> Content) {
        self.panelVm = panel
        self.content = content
    }

    var body: some View {

        // even though .vxy has only one inner view, a
        // .horizonal ScrollView shifts and truncates the inner views
        // so, perhaps there is a phantom space for indicators?
        
        if (panelVm.isVertical  ||
            panelVm.nodeType == .vxy ||
            panelVm.nodeType == .peer) {

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading,
                       spacing: spacing,
                       content: content)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom,
                       spacing: spacing,
                       content: content)
            }
        }
    }
}
