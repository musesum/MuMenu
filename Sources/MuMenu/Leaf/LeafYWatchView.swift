// created by musesum on 5/29/26

#if os(watchOS)
import SwiftUI

/// watchOS-only square panel for a single vertical-axis (Y) value.
/// The runway is the full square; the thumb is a horizontal bar spanning
/// the full width that moves up/down as the Y value changes.
struct LeafYWatchView: View {
    @ObservedObject var leafVm: LeafVm

    var body: some View {
        LeafBezelView(leafVm, .runVal) {
            LeafYBarSlideView(leafVm: leafVm)
        }
    }
}

private struct LeafYBarSlideView: View {
    @ObservedObject var leafVm: LeafVm

    var body: some View {
        GeometryReader { geo in
            let offset = leafVm.runways.valueOffset(.runVal)
            let barH   = CGFloat(LeafRunwayType.runVal.thumbRadius - 2)
            RoundedRectangle(cornerRadius: 2)
                .fill(Menu.strokeColor(leafVm.spotlight))
                .frame(width: geo.size.width, height: barH)
                .offset(x: 0, y: offset.height)
                .id(leafVm.refresh)
        }
    }
}
#endif
