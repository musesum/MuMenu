// created by musesum on 3/27/24
import SwiftUI

struct LeafTogBodyView<Content: View>: View {

    @ObservedObject var leafVm: LeafVm
    
    let content: () -> Content
    var panelVm: PanelVm { leafVm.panelVm }
    var size: CGSize { panelVm.innerPanel(.runXY) }

    init(_ leafVm: LeafVm,_  content: @escaping ()->Content) {
        self.leafVm = leafVm
        self.content = content
    }
    var body: some View {
        GeometryReader { geo in

            content() // custom control thumb is here
                .onAppear {
                    leafVm.updateRunway(.runXY, geo.frame(in: .global)) }
                .onChange(of: geo.frame(in: .global)) { leafVm.updateRunway(.runXY, $1) }
        }
        .frame(width: size.width, height: size.height)
    }
}
