//  created by musesum on 8/10/26.

#if !os(watchOS)
import SwiftUI
import MuFlo

/// sequencer leaf: piano roll above the transport row. Pinch scales the
/// loop window; beat (right) sets the loop end; panic stays rightmost.
public struct LeafSequencerView: View {

    @ObservedObject var leafVm: LeafSequencerVm
    /// once-per-press latch for the beat began-gesture
    @State private var beatPressed = false
    var size: CGSize { leafVm.panelVm.innerPanel(.none) }

    public init(leafVm: LeafSequencerVm) {
        self.leafVm = leafVm
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 4) {
            headline
            SequencerRollView(leafVm)
                .gesture(
                    MagnificationGesture()
                        .onChanged { leafVm.pinch($0) }
                        .onEnded { _ in leafVm.pinchEnded() })
            transportRow
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

    /// current / duration above the roll (monospaced, 10 Hz); the duration
    /// term tracks a live end-handle drag
    var headline: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            Text(String(format: "%.2f / %.2f s",
                        leafVm.currentSecs, leafVm.displayLoopSecs))
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundColor(.white)
        }
        .frame(height: LeafSequencerVm.headlineH)
    }

    /// skip/record(+pause while recording)/overdub/play + compact loop/
    /// undo/redo on the left; beat right (hidden while recording); panic
    /// rightmost. Width budget ≤ 8.5 d (phone portrait aspect)
    var transportRow: some View {
        HStack(spacing: Menu.diameter * 0.25) {
            symButton("backward.end", on: leafVm.playOn,
                      tint: .white, compact: true) { leafVm.tapSkipToStart() }
            recordButton
            if leafVm.recordOn { pauseButton }
            symButton("plus.circle", on: leafVm.overdubbing,
                      tint: .red, compact: true) { leafVm.tapOverdub() }
            symButton(leafVm.playOn ? "play.fill" : "play",
                      on: leafVm.playOn, tint: .green) { leafVm.toggle(leafVm.play˚) }
            symButton(leafVm.loopOn ? "arrow.trianglehead.clockwise"
                                    : "arrow.forward.to.line.compact",
                      on: leafVm.loopOn, tint: .white, compact: true) { leafVm.toggle(leafVm.loop˚) }
            symButton("arrow.uturn.backward", on: leafVm.canUndo,
                      tint: .white, compact: true) { leafVm.undoOverdub() }
            symButton("arrow.uturn.forward", on: leafVm.canRedo,
                      tint: .white, compact: true) { leafVm.redoOverdub() }
            Spacer()
            if !leafVm.recordOn { beatButton }
            svgButton("icon.panic", fallback: "exclamationmark.octagon") { leafVm.toggle(leafVm.panic˚) }
        }
        .frame(height: Menu.diameter * 0.9)
    }

    /// beat acts at touch BEGAN (a tap gesture would fire at lift and land
    /// the loop end late); the deck ignores a second press within 200 ms
    var beatButton: some View {
        let side = Menu.diameter * 0.8
        return Group {
            if let uiImage = UIImage.named("icon.heartbeat") {
                Image(uiImage: uiImage)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: side * 0.62))
            }
        }
        .foregroundColor(.white)
        .frame(width: side, height: Menu.diameter * 0.9)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !beatPressed {
                        beatPressed = true
                        leafVm.beatDown()
                    }
                }
                .onEnded { _ in
                    beatPressed = false
                    leafVm.beatUp()
                })
    }

    /// Dreamatic-resemblant record: idle = red record circle; recording =
    /// red square (stop); paused = dimmed square while pause shows resume.
    /// Overdub layering blinks the square — periodic timeline, never a
    /// repeatForever animation (rejected class)
    var recordButton: some View {
        let side = Menu.diameter * 0.8
        return TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
            let blinkOff = leafVm.overdubbing &&
                Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Image(systemName: leafVm.recordOn ? "square.fill" : "record.circle.fill")
                .font(.system(size: side * 0.62))
                .foregroundColor(.red)
                .opacity(leafVm.pauseOn ? 0.4 : blinkOff ? 0.25 : 1.0)
        }
        .frame(width: side, height: Menu.diameter * 0.9)
        .contentShape(Rectangle())
        .onTapGesture { leafVm.toggle(leafVm.record˚) }
    }
    /// while recording: pause bars; while paused: grown red resume-record
    var pauseButton: some View {
        let paused = leafVm.pauseOn
        let side = Menu.diameter * (paused ? 0.9 : 0.7)
        return Image(systemName: paused ? "record.circle.fill" : "pause.fill")
            .font(.system(size: side * 0.62))
            .foregroundColor(paused ? .red : .gray)
            .frame(width: Menu.diameter * 0.9, height: Menu.diameter * 0.9)
            .contentShape(Rectangle())
            .onTapGesture { leafVm.togglePause() }
    }

    func symButton(_ sysName: String,
                   on: Bool,
                   tint: Color,
                   compact: Bool = false,
                   action: @escaping () -> Void) -> some View {
        let side = Menu.diameter * (compact ? 0.55 : 0.8)
        return Image(systemName: sysName)
            .font(.system(size: side * 0.62))
            .foregroundColor(on ? tint : .gray)
            .frame(width: side, height: Menu.diameter * 0.9)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
    /// bundled svg icons (same assets the tape buttons used), rendered
    /// white via template mode; SF fallback
    func svgButton(_ imgName: String,
                   fallback: String,
                   action: @escaping () -> Void) -> some View {
        let side = Menu.diameter * 0.8
        return Group {
            if let uiImage = UIImage.named(imgName) {
                Image(uiImage: uiImage)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: fallback)
                    .font(.system(size: side * 0.62))
            }
        }
        .foregroundColor(.white)
        .frame(width: side, height: Menu.diameter * 0.9)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

/// piano roll canvas: arbitrary rows per event path, half-radius row
/// markers left, seconds legend bottom, playhead while transport runs
struct SequencerRollView: View {

    let leafVm: LeafSequencerVm
    /// nil until the first drag event decides activation (end-mark grab)
    @State private var edgeActive: Bool?

    static let gutter: CGFloat = 26
    /// grab margin around the end mark, points
    static let grabMargin: CGFloat = 24

    init(_ leafVm: LeafSequencerVm) {
        self.leafVm = leafVm
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    _ = timeline.date // tie the redraw to the timeline tick
                    let w = size.width
                    let h = size.height
                    let gutter = Self.gutter
                    let secondsH: CGFloat = 14
                    let rollH = h - secondsH
                    let rollW = w - gutter
                    let window = leafVm.windowSecs   // fixed axis — loop-end
                                                     // moves never rescale it
                    // panel tracks the row count off-commit (2-row floor)
                    let rowCount = leafVm.rows().count
                    Task { @MainActor in leafVm.applyRollHeight(rowCount) }
                    drawRows(context, gutter, rollW, rollH, window)
                    drawSeconds(context, gutter, rollW, rollH, secondsH, window)
                    drawEndMark(context, gutter, rollW, rollH)
                    drawPlayhead(context, gutter, rollW, rollH)
                }
            }
            // end-mark grab: activates only when the touch begins within
            // the margin of the MARK; elsewhere inert (pinch is two-finger)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let rollW = geo.size.width - Self.gutter
                        guard rollW > 0 else { return }
                        if edgeActive == nil {
                            let markX = Self.gutter + CGFloat(leafVm.endMarkNorm) * rollW
                            edgeActive = leafVm.edgeDragBegan(
                                withinGrab: abs(drag.startLocation.x - markX) <= Self.grabMargin,
                                startNorm: Double((drag.startLocation.x - Self.gutter) / rollW))
                        }
                        if edgeActive == true {
                            leafVm.edgeDragMoved(Double((drag.location.x - Self.gutter) / rollW))
                        }
                    }
                    .onEnded { _ in
                        if edgeActive == true { leafVm.edgeDragEnded() }
                        edgeActive = nil
                    })
            // a remount mid-drag never delivers onEnded — drop, no commit
            .onDisappear { leafVm.edgeDragCancel() }
        }
    }

    /// loop-end mark at its window position; follows the finger while
    /// grabbed — the axis underneath never moves
    func drawEndMark(_ context: GraphicsContext,
                     _ gutter: CGFloat, _ rollW: CGFloat, _ rollH: CGFloat) {
        let x = gutter + CGFloat(leafVm.endMarkNorm) * rollW
        var path = Path()
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: rollH))
        context.stroke(path, with: .color(.orange.opacity(0.9)), lineWidth: 2)
    }

    func drawRows(_ context: GraphicsContext,
                  _ gutter: CGFloat, _ rollW: CGFloat, _ rollH: CGFloat,
                  _ window: TimeInterval) {
        let rows = leafVm.rows()
        guard rows.count > 0, window > 0 else {
            // empty roll: faint midline invites a first recording
            var path = Path()
            path.move(to: CGPoint(x: gutter, y: rollH / 2))
            path.addLine(to: CGPoint(x: gutter + rollW, y: rollH / 2))
            context.stroke(path, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)
            return
        }
        let rowH = LeafSequencerVm.rollRowH  // fixed pack — rows never spread
        let dotR = min(rowH * 0.35, 5)
        let iconSide = Menu.radius * 0.5   // half the menu node radius
        for (row, entry) in rows.enumerated() {
            let y = (CGFloat(row) + 0.5) * rowH
            let color = LeafSequencerVm.rowColor(row, rows.count)
            // legend: the row's menu icon (white), else its letter
            switch leafVm.rowIcon(entry.key) {
            case .image(let ui):
                var img = context.resolve(Image(uiImage: ui).renderingMode(.template))
                img.shading = .color(.white)
                context.draw(img, in: CGRect(x: gutter / 2 - iconSide / 2,
                                             y: y - iconSide / 2,
                                             width: iconSide, height: iconSide))
            case .letter(let s):
                context.draw(
                    Text(s).font(.system(size: iconSide, weight: .semibold))
                        .foregroundColor(.white),
                    at: CGPoint(x: gutter / 2, y: y))
            }
            // begin marker + tail per segment (intermediates replay verbatim;
            // the roll shows one span from touch-begin to touch-end).
            // Segments past the loop end stay visible but dimmed
            let loopEnd = leafVm.loopSecs
            for seg in entry.segments where seg.start <= window {
                let dim: Double = seg.start > loopEnd ? 0.35 : 1
                let x0 = gutter + CGFloat(seg.start / window) * rollW
                let x1 = gutter + CGFloat(min(seg.end, window) / window) * rollW
                if x1 - x0 > 1 {
                    var tail = Path()
                    tail.move(to: CGPoint(x: x0, y: y))
                    tail.addLine(to: CGPoint(x: x1, y: y))
                    context.stroke(tail, with: .color(color.opacity(0.7 * dim)),
                                   lineWidth: max(2, dotR * 0.6))
                }
                context.fill(
                    Path(ellipseIn: CGRect(x: x0 - dotR, y: y - dotR,
                                           width: dotR * 2, height: dotR * 2)),
                    with: .color(color.opacity(dim)))
            }
        }
    }

    /// bottom legend: loop time in seconds
    func drawSeconds(_ context: GraphicsContext,
                     _ gutter: CGFloat, _ rollW: CGFloat,
                     _ rollH: CGFloat, _ secondsH: CGFloat,
                     _ window: TimeInterval) {
        guard window > 0 else { return }
        let step = max(1.0, (window / 8).rounded())
        var ticks = Path()
        var second = 0.0
        while second <= window {
            let x = gutter + CGFloat(second / window) * rollW
            ticks.move(to: CGPoint(x: x, y: rollH))
            ticks.addLine(to: CGPoint(x: x, y: rollH + 4))
            context.draw(
                Text("\(Int(second))")
                    .font(.system(size: 8))
                    .foregroundColor(.gray),
                at: CGPoint(x: x, y: rollH + secondsH * 0.7))
            second += step
        }
        context.stroke(ticks, with: .color(.gray.opacity(0.7)), lineWidth: 0.5)
    }

    func drawPlayhead(_ context: GraphicsContext,
                      _ gutter: CGFloat, _ rollW: CGFloat, _ rollH: CGFloat) {
        guard let norm = leafVm.playheadNorm() else { return }
        let x = gutter + CGFloat(norm) * rollW
        var path = Path()
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: rollH))
        context.stroke(path, with: .color(.white.opacity(0.85)), lineWidth: 1)
    }
}
#endif
