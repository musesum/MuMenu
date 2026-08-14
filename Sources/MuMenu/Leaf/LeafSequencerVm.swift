//  created by musesum on 8/10/26.

#if !os(watchOS)
import SwiftUI
import MuFlo

/// tape sequencer leaf: freeform piano roll over the recorded events with
/// the transport (record/play/loop/learn), a beat button that sets the
/// loop end, and panic. Buttons write the SAME tape.* flo nodes TapeFlo
/// binds — deck, peer sync, and PanicState behavior are unchanged.
public class LeafSequencerVm: LeafVm {

    /// app-injected transport (SkyModel: `LeafSequencerVm.tape = { tapeFlo }`)
    /// so MuMenu never owns the TapeFlo lifecycle
    nonisolated(unsafe) public static var tape: (@Sendable () -> TapeFlo?)?

    var record˚ : Flo?
    var play˚   : Flo?
    var loop˚   : Flo?
    var beat˚   : Flo?
    var panic˚  : Flo?
    var pause˚  : Flo?

    /// display loop window before any recording exists
    var localLoop: TimeInterval = 8
    private var pinchAnchor: TimeInterval?

    override init(_ menuTree: MenuTree,
                  _ branchVm: BranchVm,
                  _ prevVm: NodeVm?,
                  _ runTypes: [LeafRunwayType]) {

        super.init(menuTree, branchVm, prevVm, runTypes)

        let tape = menuTree.flo // leaf wraps the tape node itself
        // bind — the same resolver TapeFlo uses (same node, same closures)
        record˚ = tape.bind("record")
        play˚   = tape.bind("play")
        loop˚   = tape.bind("loop")
        beat˚   = tape.bind("beat")
        panic˚  = tape.bind("panic")
        pause˚  = tape.bind("pause")

        // state changes (peer, plugin, tape exclusivity) redraw the buttons;
        // closures may fire off-main — hop before touching the view
        for flo in [record˚, play˚, loop˚, panic˚, pause˚] {
            flo?.addClosure { [weak self] _, _ in
                Task { @MainActor in self?.refreshView() }
            }
        }
    }

    /// recording sessions pin the tree open (LeafGraphVm precedent);
    /// tap-root fold and the root-escape drag still close it deliberately
    override public var disablesAutoFade: Bool { true }

    override public func touchLeaf(_: TouchState, _: Visitor) {} // native gestures
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { menuTree.flo.name }
    override public func syncVal(_: Visitor) {}

    // boolVal("x"), never `bool` — the menu 0 component shadows x in
    // BoolVal's first-scalar dictionary scan, and tween lags the write
    var recordOn : Bool { record˚?.boolVal("x") ?? false }
    var playOn   : Bool { play˚?.boolVal("x")   ?? false }
    var loopOn   : Bool { loop˚?.boolVal("x")   ?? false }
    var pauseOn  : Bool { pause˚?.boolVal("x")  ?? false }

    /// mid-record pause toggle (Dreamatic recordSetPaused flow on tape.pause)
    public func togglePause() {
        guard recordOn else { return }
        toggle(pause˚)
    }

    /// loop end in seconds: live tape window, else local default
    public var loopSecs: TimeInterval {
        Self.tape?()?.loopSeconds ?? localLoop
    }
    /// display window = recorded content extent (live while recording), or
    /// the loop end when pinch pushes it past the content. Loop-end moves
    /// NEVER rescale the axis — that is the batch-7 contract
    public var windowSecs: TimeInterval {
        guard let tapeFlo = Self.tape?() else { return localLoop }
        var longest: TimeInterval = 0
        for track in tapeFlo.recordedTracks {
            longest = max(longest, track.trackDuration)
            if track.isRecording { longest = max(longest, track.recordElapsed) }
        }
        let window = max(longest, tapeFlo.loopSeconds ?? 0)
        return window > 0 ? window : localLoop
    }
    /// loop duration for the headline — live value while the end handle
    /// drags, committed value otherwise
    public var displayLoopSecs: TimeInterval {
        if let window = windowAnchor, let norm = edgeDragNorm {
            return min(120, max(1, window * norm))
        }
        return loopSecs
    }
    /// live transport time for the headline: play phase, else take elapsed
    public var currentSecs: TimeInterval {
        guard let tapeFlo = Self.tape?() else { return 0 }
        if let phase = tapeFlo.playPhase { return phase }
        if let recording = tapeFlo.recordedTracks.first(where: { $0.isRecording }) {
            return recording.recordElapsed
        }
        return 0
    }
    /// loop-end mark position in the window (live drag value while grabbed)
    public var endMarkNorm: Double {
        if let edgeDragNorm { return edgeDragNorm }
        let window = windowSecs
        guard window > 0 else { return 1 }
        return min(1, loopSecs / window)
    }

    /// store silently, then announce — a bare .fire can run closures before
    /// the written scalar settles (they read the stale/default value)
    private func storeFire(_ flo: Flo?, _ x: Double) {
        guard let flo else { return }
        flo.setNameNums([("x", x)], .sneak, Visitor(0, .user))
        flo.setNameNums([("x", x)], .fire, Visitor(0, .user))
        refreshView()
    }
    public func toggle(_ flo: Flo?) {
        guard let flo else { return }
        storeFire(flo, flo.boolVal("x") ? 0 : 1)
    }
    /// beat acts at touch BEGAN — the loop end lands on the press, not
    /// the lift; release still writes x 0 for peers and learned controls
    public func beatDown() { storeFire(beat˚, 1) }
    public func beatUp()   { storeFire(beat˚, 0) }

    /// pinch scales the loop end INVERSELY (pinch-in lengthens, pinch-out
    /// tightens — swapped per Dev); a pinch whose first finger landed in
    /// the grab zone preempts the edge drag
    public func pinch(_ scale: CGFloat) {
        edgeDragCancel()
        let anchor = pinchAnchor ?? loopSecs
        pinchAnchor = anchor
        guard scale > 0 else { return }
        setLoop(anchor / Double(scale))
    }
    public func pinchEnded() { pinchAnchor = nil }

    /// clamp + route a loop-window change (live tape, else local default)
    private func setLoop(_ seconds: TimeInterval) {
        let next = min(120, max(1, seconds))
        if let tapeFlo = Self.tape?(), tapeFlo.loopSeconds != nil {
            tapeFlo.setLoopDuration(next)
        } else {
            localLoop = next
        }
        refreshView()
    }

    /// end-mark grab: the mark moves within the FIXED window; the new
    /// loop end commits on release. Extension past recorded content is
    /// pinch's job — the mark caps at the window edge
    var edgeDragNorm: Double?
    private var windowAnchor: TimeInterval?
    private var edgeStartNorm: Double?
    private var edgeMarkStart: Double?

    public func edgeDragBegan(withinGrab: Bool, startNorm: Double) -> Bool {
        guard withinGrab else { return false }
        windowAnchor = windowSecs
        edgeStartNorm = startNorm
        edgeMarkStart = endMarkNorm
        edgeDragNorm = edgeMarkStart
        return true
    }
    public func edgeDragMoved(_ norm: Double) {
        guard windowAnchor != nil,
              let startNorm = edgeStartNorm,
              let markStart = edgeMarkStart else { return }
        // offset mapping — the mark moves by the finger's TRAVEL, not to
        // its absolute position; a stationary grab commits no change
        edgeDragNorm = min(1, max(0.02, markStart + norm - startNorm))
        refreshView()
    }
    public func edgeDragEnded() {
        guard let window = windowAnchor, let norm = edgeDragNorm else { return }
        edgeDragClear()
        setLoop(window * norm)
    }
    /// remount or pinch preemption: drop the gesture without committing
    public func edgeDragCancel() {
        guard windowAnchor != nil else { return }
        edgeDragClear()
        refreshView()
    }
    private func edgeDragClear() {
        windowAnchor = nil
        edgeStartNorm = nil
        edgeMarkStart = nil
        edgeDragNorm = nil
    }

    /// skip to the beginning of the loop (deck restart, no end-mark logic)
    public func tapSkipToStart() {
        Self.tape?()?.skipToStart()
        refreshView()
    }

    /// (+) — layer a new take over the existing loop; auto-starts playback
    public func tapOverdub() {
        guard let tapeFlo = Self.tape?(), tapeFlo.loopSeconds != nil else { return }
        guard !recordOn else { return }
        if !playOn { storeFire(play˚, 1) }
        storeFire(record˚, 1)
    }
    /// blink gate: the deck is layering over a running loop
    var overdubbing: Bool { Self.tape?()?.isOverdubbing ?? false }

    /// undo/redo act on whole overdub layers; parked while recording
    var canUndo: Bool { !recordOn && (Self.tape?()?.canUndoOverdub ?? false) }
    var canRedo: Bool { !recordOn && (Self.tape?()?.canRedoOverdub ?? false) }
    public func undoOverdub() {
        guard canUndo else { return }
        Self.tape?()?.undoOverdub()
        refreshView()
    }
    public func redoOverdub() {
        guard canRedo else { return }
        Self.tape?()?.redoOverdub()
        refreshView()
    }

    /// one drawn span on a roll row: begin marker at start, tail to end
    public struct RollSegment {
        public let start: TimeInterval
        public let end: TimeInterval
    }
    /// gap that splits phase-less streams (midi, controllers) into segments
    static let segmentGap: TimeInterval = 0.35
    /// fixed roll row height — rows pack instead of spreading; the panel
    /// starts two rows tall and grows as new event types add rows
    nonisolated static let rollRowH: CGFloat = 28
    /// current-time headline strip above the roll
    nonisolated static let headlineH: CGFloat = 16
    /// headline + seconds strip + transport row + spacings + padding
    nonisolated static let chromeH: CGFloat = 84

    private var lastRowCount = 0
    /// resize the panel for the row count (LeafGraphVm aspect mechanism);
    /// called via a hop from the roll's redraw tick, never mid-commit
    public func applyRollHeight(_ rowCount: Int) {
        let count = max(2, rowCount)
        guard count != lastRowCount else { return }
        lastRowCount = count
        let width = panelVm.aspectSz.width * Menu.diameter
        let height = CGFloat(count) * Self.rollRowH + Self.chromeH
        let unit = CGSize(width: width / Menu.diameter,
                          height: height / Menu.diameter)
        panelVm.aspectSz = unit
        branchVm.panelVm.aspectSz = unit
        refreshView()
    }

    /// roll rows: row key → begin+tail segments, first-seen order across
    /// trackId-sorted tracks. A finger slot > 1 suffixes the key so each
    /// concurrent finger lands on its own adjacent row cluster
    public func rows() -> [(key: String, segments: [RollSegment])] {
        guard let tapeFlo = Self.tape?() else { return [] }
        var order = [String]()
        var open  = [String: TimeInterval]()          // rowKey → open segment start
        var last  = [String: TimeInterval]()          // rowKey → last event time
        var segs  = [String: [RollSegment]]()
        func close(_ key: String) {
            if let start = open.removeValue(forKey: key) {
                segs[key, default: []].append(RollSegment(start: start, end: last[key] ?? start))
            }
        }
        // creation order — a random-trackId sort let a new layer's rows
        // insert BEFORE the first take's
        let tracks = tapeFlo.orderedTracks
        for (trackIdx, track) in tracks.enumerated() {
            for event in track.tapeEvents.sorted(by: { $0.time < $1.time }) {
                let fingerKey = (event.finger ?? 1) > 1
                    ? "\(event.key) \(event.finger ?? 1)" : event.key
                // each layer owns its rows — same-type events from another
                // track must never overlay (space suffix keeps icon lookup)
                let key = trackIdx > 0 ? "\(fingerKey) ~\(trackIdx)" : fingerKey
                if segs[key] == nil, open[key] == nil { order.append(key) }
                switch event.phase {
                case 0:                              // began: fresh segment
                    close(key)
                    open[key] = event.time
                case 2:                              // ended: close through here
                    last[key] = event.time
                    close(key)
                default:                             // moved or instantaneous
                    if open[key] == nil {
                        open[key] = event.time
                    } else if event.phase == nil,
                              let prior = last[key],
                              event.time - prior > Self.segmentGap {
                        close(key)                   // stream gap → new segment
                        open[key] = event.time
                    }
                }
                last[key] = event.time
            }
            for key in Array(open.keys) { close(key) }  // track tail
            last.removeAll()
        }
        return order.map { ($0, segs[$0] ?? []) }
    }

    /// row legend: the row's menu icon, or a letter fallback
    public enum RowIcon { case image(UIImage), letter(String) }
    private var rowIconCache = [String: RowIcon]()
    private lazy var rootFlo: Flo = {
        var flo = menuTree.flo
        while let parent = flo.parent { flo = parent }
        return flo
    }()
    public func rowIcon(_ key: String) -> RowIcon {
        if let cached = rowIconCache[key] { return cached }
        let base = key.split(separator: " ").first.map(String.init) ?? key
        // type rows map to their canonical menu nodes; path rows to themselves
        let node: Flo? = switch base {
        case "touchCanvas" : rootFlo.findPath("brush")
        case "midiItem"    : rootFlo.findPath("music")
        default            : rootFlo.findPath(base)
        }
        var icon: RowIcon?
        if let nameAny = node?.exprs?.nameAny {
            for (kind, any) in nameAny {
                guard let name = any as? String else { continue }
                switch kind {
                case "sym":
                    if let ui = UIImage(systemName: name) { icon = .image(ui) }
                case "img", "svg":
                    if let ui = UIImage.named(name) { icon = .image(ui) }
                default: continue
                }
                if icon != nil { break }
            }
        }
        let lastSegment = base.split(separator: ".").last.map(String.init) ?? base
        let resolved = icon ?? .letter(String(lastSegment.prefix(1)).uppercased())
        rowIconCache[key] = resolved
        return resolved
    }

    /// normalized playhead 0…1 while playing or recording, nil when idle;
    /// scaled against the FIXED display window, so it wraps at the mark
    public func playheadNorm() -> Double? {
        guard let tapeFlo = Self.tape?() else { return nil }
        let window = windowSecs
        guard window > 0 else { return nil }
        // task-keyed deck phase — playState.play misses the first pass
        if let phase = tapeFlo.playPhase {
            return min(1, phase / window)
        }
        if let recording = tapeFlo.recordedTracks.first(where: { $0.isRecording }) {
            // fresh take: the window grows with the take — head rides the
            // recorded edge
            return min(1, recording.recordElapsed / window)
        }
        return nil
    }

    /// stable row hue for markers and event dots
    public static func rowColor(_ row: Int, _ count: Int) -> Color {
        Color(hue: Double(row) / Double(max(count, 1)),
              saturation: 0.7, brightness: 0.9)
    }
}
#endif
