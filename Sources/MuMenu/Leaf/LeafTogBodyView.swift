// created by musesum on 3/27/24
import SwiftUI

struct LeafTogBodyView<Content: View>: View {

    @ObservedObject var leafVm: LeafVm

    let content: () -> Content
    var panelVm: PanelVm { leafVm.panelVm }
    var size: CGSize { panelVm.inner(.xy) }

    init(_ leafVm: LeafVm,_  content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }
    var body: some View {
        GeometryReader { geo in

            content() // custom control thumb is here
                .onAppear {
                    leafVm.updateRunway(.xy, geo.frame(in: .global)) }
#if os(visionOS)
                .onChange(of: geo.frame(in: .global)) { old, now in leafVm.updateRunway(.xy, now) }
#else
                .onChange(of: geo.frame(in: .global)) { leafVm.updateRunway(.xy, $0) }
#endif
        }
        .frame(width: size.width, height: size.height)
    }
}

