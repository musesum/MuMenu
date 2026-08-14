//  created by musesum on 8/10/26.

#if !os(watchOS)
import SwiftUI
import MuFlo

/// midi grid leaf: 11×8 note lattice with velocity circles (log radius),
/// a minimal piano line-drawing legend, and a midi/mic source radio
public struct LeafMidiView: View {

    @ObservedObject var leafVm: LeafMidiVm
    var size: CGSize { leafVm.panelVm.innerPanel(.none) }

    public init(leafVm: LeafMidiVm) {
        self.leafVm = leafVm
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 4) {
            LeafMidiGridView(leafVm)
            sourceRadio
            // region always reserved — the grid never squashes on a source
            // switch; contents live only in mic mode
            micSliders
                .opacity(leafVm.source == 1 ? 1 : 0)
                .allowsHitTesting(leafVm.source == 1)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: Menu.cornerRadius)
                .fill(.ultraThickMaterial)
                .overlay(RoundedRectangle(cornerRadius: Menu.cornerRadius)
                    .stroke(Menu.strokeColor(leafVm.spotlight),
                            lineWidth: Menu.strokeWidth(leafVm.spotlight))))
        .frame(width: size.width, height: size.height)
    }

    /// midi/mic radio — writes the SAME music.x the flo graph carries
    var sourceRadio: some View {
        HStack(spacing: Menu.diameter) {
            radioIcon("pianokeys", 0)
            radioIcon("mic", 1)
        }
        .frame(height: Menu.diameter * 0.8)
    }
    /// mic-only: sensitivity (note-vs-noise floor) + simultaneous-note cap
    var micSliders: some View {
        VStack(spacing: 3) {
            miniSlider("sens", value: leafVm.sensitivity) { leafVm.setSensitivity($0) }
            miniSlider("poly", value: Double(leafVm.polyphony - 1) / 7.0) { leafVm.setPolyphony($0) }
        }
        .frame(height: Menu.diameter * 0.7)
        .padding(.horizontal, 6)
    }
    func miniSlider(_ label: String,
                    value: Double,
                    set: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.gray)
                .frame(width: 24, alignment: .trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.3))
                    Capsule().fill(LeafMidiVm.sourceColor(1).opacity(0.7))
                        .frame(width: max(6, geo.size.width * value))
                }
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { set($0.location.x / max(1, geo.size.width)) })
            }
            .frame(height: 8)
        }
    }

    func radioIcon(_ sysName: String, _ src: Int) -> some View {
        let selected = leafVm.source == src
        return Image(systemName: sysName)
            .font(.system(size: Menu.diameter * 0.5))
            .foregroundColor(selected ? LeafMidiVm.sourceColor(src) : .gray)
            .frame(width: Menu.diameter, height: Menu.diameter * 0.8)
            .overlay(RoundedRectangle(cornerRadius: Menu.cornerRadius)
                .stroke(selected ? LeafMidiVm.sourceColor(src) : .clear,
                        lineWidth: 1))
            .onTapGesture { leafVm.setSource(src) }
    }
}

/// grid + piano legend canvas; 30 Hz timeline drives the live mic redraw
struct LeafMidiGridView: View {

    let leafVm: LeafMidiVm

    init(_ leafVm: LeafMidiVm) {
        self.leafVm = leafVm
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                _ = timeline.date // tie the redraw to the timeline tick
                let w = size.width
                let h = size.height
                let legendH = min(h * 0.16, 26)
                let gridH = h - legendH - 4

                drawLattice(context, w, gridH)
                drawNotes(context, w, gridH)
                drawPiano(context, w, legendH, atY: gridH + 4)
            }
        }
    }

    /// lattice geometry — cells sized so a max-radius bloom (slotRatio ×
    /// cell = 0.31 × cell past the center row/col) stays inside a 0.35 ×
    /// cell border margin, untruncated
    struct GridGeo {
        let cellW: CGFloat, cellH: CGFloat
        let marginX: CGFloat, marginY: CGFloat
        init(_ w: CGFloat, _ gridH: CGFloat) {
            cellW = w / (CGFloat(LeafMidiVm.cols) + 0.7)
            cellH = gridH / (CGFloat(LeafMidiVm.rows) + 0.7)
            marginX = cellW * 0.35
            marginY = cellH * 0.35
        }
        func center(_ num: Int, _ gridH: CGFloat) -> CGPoint {
            let (col, row) = LeafMidiVm.colRow(num)
            return CGPoint(x: marginX + (CGFloat(col) + 0.5) * cellW,
                           y: gridH - marginY - (CGFloat(row) + 0.5) * cellH) // row 0 bottom
        }
    }

    /// 128 base dots
    func drawLattice(_ context: GraphicsContext, _ w: CGFloat, _ gridH: CGFloat) {
        let geo = GridGeo(w, gridH)
        var dots = Path()
        for num in LeafMidiVm.noteLo ... LeafMidiVm.noteHi {
            let c = geo.center(num, gridH)
            dots.addEllipse(in: CGRect(x: c.x - 1.5, y: c.y - 1.5, width: 3, height: 3))
        }
        context.fill(dots, with: .color(.gray.opacity(0.5)))
    }

    /// active-note circles: radius = loudness on a log scale, from a
    /// recognizable dot up to 1.62 × the slot (circles bloom past cells)
    func drawNotes(_ context: GraphicsContext, _ w: CGFloat, _ gridH: CGFloat) {
        let geo = GridGeo(w, gridH)
        let rMax = min(geo.cellW, geo.cellH) * LeafMidiVm.slotRatio
        let rMin = LeafMidiVm.radiusMin

        func draw(_ notes: [Int: Float], _ color: Color) {
            for (num, velo) in notes {
                let c = geo.center(num, gridH)
                let norm = CGFloat(log(1 + Double(velo)) / log(128.0))
                let r = rMin + (rMax - rMin) * norm
                let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.55)))
                context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 1)
            }
        }
        if leafVm.source == 0 {
            draw(leafVm.activeNotes, LeafMidiVm.sourceColor(0))
        } else {
            let bins = LeafMidiVm.fftBins?() ?? []
            draw(LeafMidiVm.fftNoteVelocities(bins,
                                              threshold: leafVm.fftThreshold,
                                              maxNotes: leafVm.polyphony,
                                              level: LeafMidiVm.micLevelGate()),
                 LeafMidiVm.sourceColor(1))
        }
    }

    /// one-octave legend: 12 slots tracking the inset grid columns
    /// (C-aligned) — naturals outlined, sharps filled
    func drawPiano(_ context: GraphicsContext, _ w: CGFloat, _ legendH: CGFloat, atY y: CGFloat) {
        let geo = GridGeo(w, w) // horizontal terms only
        var lines = Path()
        var sharps = Path()
        for col in 0 ..< LeafMidiVm.cols {
            let x = geo.marginX + CGFloat(col) * geo.cellW
            if LeafMidiVm.sharpCols.contains(col) {
                sharps.addRect(CGRect(x: x + geo.cellW * 0.15, y: y,
                                      width: geo.cellW * 0.7, height: legendH * 0.6))
            } else {
                lines.addRect(CGRect(x: x, y: y, width: geo.cellW, height: legendH))
            }
        }
        context.stroke(lines, with: .color(.gray.opacity(0.7)), lineWidth: 0.5)
        context.fill(sharps, with: .color(.gray.opacity(0.7)))
    }
}
#endif
