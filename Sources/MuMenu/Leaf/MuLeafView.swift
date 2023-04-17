//  Created by warren on 6/21/22.

import SwiftUI

/// Generic layout of title and control based on axis
struct MuLeafView<Content: View>: View {

    let leafVm: MuLeafVm
    let content: () -> Content
    var panelVm: MuPanelVm { leafVm.panelVm }

    init(_ leafVm: MuLeafVm, @ViewBuilder content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }

    var body: some View {

        if leafVm.nodeType.isTog {

            MuTogBodyView(leafVm, content)
            
        } else if panelVm.isVertical {
            VStack {
                // vertical title is always on top
                // so that hand doesn't occlude value text
                MuLeafTitleView(leafVm)
                MuLeafBodyView(leafVm, content)
            }
        } else {
            HStack {
                // horizontal title is farthest away from root
                // to allow control to be a bit more reachable
                if panelVm.cornerAxis.corner.left {
                    MuLeafBodyView(leafVm, content)
                    MuLeafTitleView(leafVm)
                } else {
                    MuLeafTitleView(leafVm)
                    MuLeafBodyView(leafVm, content)
                }
            }
        }
    }
}

/// title showing position of control
struct MuLeafTitleView: View {

    @ObservedObject var leafVm: MuLeafVm
    var panelVm: MuPanelVm { leafVm.panelVm }
    var leafTitle: String { leafVm.leafProto?.leafTitle() ?? "??"}

    init(_ leafVm: MuLeafVm) {
        self.leafVm = leafVm
    }
    var body: some View {
        Text(leafTitle)
            .scaledToFit()
            .allowsTightening(true)
            .font(Font.system(size: 14, design: .default))
            .minimumScaleFactor(0.01)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 1.0)
            .frame(width:  panelVm.titleSize.width,
                   height: panelVm.titleSize.height,
                   alignment: .center)
    }
}

/// Panel and closure(Content) for thumb of control
///
/// called by `MuLeaf*View` with only the control inside the panel
/// passed through as a closure
///
struct MuLeafBodyView<Content: View>: View {

    @ObservedObject var leafVm: MuLeafVm
    let content: () -> Content
    var panelVm: MuPanelVm { leafVm.panelVm }

    init(_ leafVm: MuLeafVm,_  content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }
    var body: some View {
        GeometryReader { geo in
            MuPanelView(leafVm: leafVm)
            content() // custom control thumb is here
                .onAppear { leafVm.updateRunway(geo.frame(in: .global)) }
                .onChange(of: geo.frame(in: .global)) { leafVm.updateRunway($0) }
        }
        .frame(width: panelVm.inner.width, height: panelVm.inner.height)
    }
}

struct MuTogBodyView<Content: View>: View {

    @ObservedObject var leafVm: MuLeafVm
    let content: () -> Content
    var panelVm: MuPanelVm { leafVm.panelVm }

    init(_ leafVm: MuLeafVm,_  content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }
    var body: some View {
        GeometryReader { geo in

            content() // custom control thumb is here
                .onAppear { leafVm.updateRunway(geo.frame(in: .global)) }
                .onChange(of: geo.frame(in: .global)) { leafVm.updateRunway($0) }
        }
        .frame(width: panelVm.inner.width, height: panelVm.inner.height)
    }
}

