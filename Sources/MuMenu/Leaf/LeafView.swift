//  created by musesum on 6/21/22.

import SwiftUI

/// Generic layout of title and control based on axis
struct LeafView<Content: View>: View {

    let leafVm: LeafVm
    let content: () -> Content
    var panelVm: PanelVm { leafVm.panelVm }

    init(_ leafVm: LeafVm, @ViewBuilder content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }

    var body: some View {

        if leafVm.nodeType.isTog {

            TogBodyView(leafVm, content)
            
        } else if panelVm.isVertical {
            VStack {
                // vertical title is always on top
                // so that hand doesn't occlude value text
                LeafTitleView(leafVm)
                LeafBodyView(leafVm, content)
            }
        } else {
            HStack {
                // horizontal title is farthest away from root
                // to allow control to be a bit more reachable
                if panelVm.cornerAxis.corner.left {
                    LeafBodyView(leafVm, content)
                    LeafTitleView(leafVm)
                } else {
                    LeafTitleView(leafVm)
                    LeafBodyView(leafVm, content)
                }
            }
        }
    }
}

/// title showing position of control
struct LeafTitleView: View {

    @ObservedObject var leafVm: LeafVm
    var panelVm: PanelVm { leafVm.panelVm }
    var leafTitle: String { leafVm.leafProto?.leafTitle() ?? "??"}

    init(_ leafVm: LeafVm) {
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
struct LeafBodyView<Content: View>: View {

    @ObservedObject var leafVm: LeafVm
    let content: () -> Content
    var panelVm: PanelVm { leafVm.panelVm }

    init(_ leafVm: LeafVm,_  content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }
    var body: some View {
        GeometryReader { geo in
            PanelView(leafVm: leafVm)
            content() // custom control thumb is here
                .onAppear { leafVm.updateRunway(geo.frame(in: .global)) }
            #if os(visionOS)
                .onChange(of: geo.frame(in: .global)) { old, now in leafVm.updateRunway(now) }
            #else
                .onChange(of: geo.frame(in: .global)) { leafVm.updateRunway($0) }
            #endif
        }
        .frame(width: panelVm.inner.width, height: panelVm.inner.height)
    }
}

struct TogBodyView<Content: View>: View {

    @ObservedObject var leafVm: LeafVm
    let content: () -> Content
    var panelVm: PanelVm { leafVm.panelVm }

    init(_ leafVm: LeafVm,_  content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }
    var body: some View {
        GeometryReader { geo in

            content() // custom control thumb is here
                .onAppear { leafVm.updateRunway(geo.frame(in: .global)) }
            #if os(visionOS)
                .onChange(of: geo.frame(in: .global)) { old, now in leafVm.updateRunway(now) }
            #else
                .onChange(of: geo.frame(in: .global)) { leafVm.updateRunway($0) }
            #endif
        }
        .frame(width: panelVm.inner.width, height: panelVm.inner.height)
    }
}

