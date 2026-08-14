//  created by musesum on 7/12/26.

import SwiftUI
import MuFlo

/// VF layout = XYZW frame with two live sliders: v (volume) in the y slot,
/// f (band-pass) in the w slot. The x/z slots are grayed placeholders and
/// the center pad is a display-only scope: blue = band-pass response
/// centered at f, green = live PCM samples from LeafVfVm.pcm.
/// Neither the grayed slots nor the scope register runway bounds
/// (registration lives in LeafBezelView's content closure, which they
/// never use), so touches there can never land on a thumb.
public struct LeafVfView: View {

    @ObservedObject var leafVm: LeafVfVm

    public init(leafVm: LeafVfVm) {
        self.leafVm = leafVm
    }

    /// bezel visual for the disabled x/z slots — same shape as
    /// LeafBezelView, dimmed, no bounds registration
    private func grayBezel(_ type: LeafRunwayType) -> some View {
        let size = leafVm.panelVm.innerPanel(type)
        return RoundedRectangle(cornerRadius: Menu.cornerRadius)
            .fill(PanelSkin.material)
            .overlay(RoundedRectangle(cornerRadius: Menu.cornerRadius)
                .fill(PanelSkin.tint))
            .overlay(RoundedRectangle(cornerRadius: Menu.cornerRadius)
                .stroke(Menu.strokeColor(false),
                        lineWidth: Menu.strokeWidth(false))
                .opacity(0.25))   // the dimmed stroke is what still reads as off
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 0) {

            HStack(alignment: .center, spacing: 4) {

                LeafHeaderDeltaView(leafVm)
                    #if os(watchOS)
                    .padding(EdgeInsets(top: 2, leading: 2, bottom: 0, trailing: 0))
                    #else
                    .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 0))
                    #endif
                grayBezel(.runX)
                Spacer()
            }

            HStack(alignment: .center, spacing: 4) {

                LeafBezelView(leafVm, .runY) {
                    LeafThumbSlideView(leafVm, .runY)
                }
                LeafScopeView(leafVm) // display-only: no bounds, no thumb
                grayBezel(.runZ)
            }

            // f on the bottom, aligned horizontally with the grayed x slot:
            // the invisible header twin reserves the identical leading width
            HStack(alignment: .center, spacing: 4) {

                LeafHeaderDeltaView(leafVm)
                    #if os(watchOS)
                    .padding(EdgeInsets(top: 2, leading: 2, bottom: 0, trailing: 0))
                    #else
                    .padding(EdgeInsets(top: 2, leading: 4, bottom: 0, trailing: 0))
                    #endif
                    .opacity(0)
                    .allowsHitTesting(false)
                LeafBezelView(leafVm, .runW) {
                    LeafThumbSlideView(leafVm, .runW)
                }
                Spacer()
            }
        }
    }
}

/// center scope: band-pass response curve (blue) + live PCM polyline
/// (green), redrawn at 30 Hz only while mounted
struct LeafScopeView: View {

    let leafVm: LeafVfVm
    var size: CGSize { leafVm.panelVm.innerPanel(.runXY) }

    init(_ leafVm: LeafVfVm) {
        self.leafVm = leafVm
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            Canvas { context, canvasSize in
                _ = timeline.date // tie the redraw to the timeline tick
                let w = canvasSize.width
                let h = canvasSize.height
                let midY = h / 2

                // blue: band-pass response bell centered at f — x mirrors
                // the runW slider's log-frequency sweep position
                let cx = leafVm.fNorm * w
                let sigma = w / 10
                var bandPath = Path()
                let steps = 64
                for i in 0 ... steps {
                    let x = CGFloat(i) / CGFloat(steps) * w
                    let g = exp(-pow((x - cx) / sigma, 2))
                    let y = h - 4 - g * (h - 8)
                    i == 0 ? bandPath.move(to: CGPoint(x: x, y: y))
                           : bandPath.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(bandPath, with: .color(.blue), lineWidth: 1.5)

                // green: live PCM samples, -1…1 → vertical around center;
                // no tap running (nil/empty) draws a flat centerline
                let samples = LeafVfVm.pcm?() ?? []
                var pcmPath = Path()
                if samples.count > 1 {
                    let count = samples.count
                    for i in 0 ..< count {
                        let x = CGFloat(i) / CGFloat(count - 1) * w
                        let clamped = max(-1, min(1, CGFloat(samples[i])))
                        let y = midY - clamped * (h / 2 - 4)
                        i == 0 ? pcmPath.move(to: CGPoint(x: x, y: y))
                               : pcmPath.addLine(to: CGPoint(x: x, y: y))
                    }
                } else {
                    pcmPath.move(to: CGPoint(x: 0, y: midY))
                    pcmPath.addLine(to: CGPoint(x: w, y: midY))
                }
                context.stroke(pcmPath, with: .color(.green), lineWidth: 1.0)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Menu.cornerRadius)
                .fill(PanelSkin.material)
                .overlay(RoundedRectangle(cornerRadius: Menu.cornerRadius)
                    .fill(PanelSkin.tint))
                .overlay(RoundedRectangle(cornerRadius: Menu.cornerRadius)
                    .stroke(Menu.strokeColor(leafVm.spotlight),
                            lineWidth: Menu.strokeWidth(leafVm.spotlight))))
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}
