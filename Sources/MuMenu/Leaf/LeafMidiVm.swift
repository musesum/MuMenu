//  created by musesum on 8/10/26.

#if !os(watchOS)
import SwiftUI
import MuFlo

/// 88-note grid leaf: 11×8 dots (A0 bottom-left ascending), lit by
/// midi.input.note events or by mic FFT peaks, source-selected by
/// the music node's x (0 midi, 1 microphone)
public class LeafMidiVm: LeafVm {

    /// live FFT magnitude bins — injected by the app (SkyModel:
    /// `LeafMidiVm.fftBins = { micTap.fft }`) so MuMenu carries no
    /// MuAudio dependency; nil or empty lights nothing
    nonisolated(unsafe) public static var fftBins: (@Sendable () -> [Float])?
    /// raw time-domain samples for ABSOLUTE loudness — the FFT bins are
    /// per-buffer max-normalized, so without this gate a quiet room's hum
    /// reads full scale
    nonisolated(unsafe) public static var micRaw: (@Sendable () -> [Float])?

    /// absolute-loudness gate 0…1 from raw-sample RMS: floor 0.01, slope 8
    public static func micLevelGate() -> Float {
        guard let samples = micRaw?(), !samples.isEmpty else { return 0 }
        let meanSq = samples.reduce(Float(0)) { $0 + $1 * $1 } / Float(samples.count)
        let rms = meanSq.squareRoot()
        return min(1, max(0, (rms - 0.01) * 8))
    }

    nonisolated static let noteLo = 0  // full MIDI range
    nonisolated static let noteHi = 127
    nonisolated static let cols = 12   // pitch classes, C-aligned (col 0 = C)
    nonisolated static let rows = 11   // octave rows; row 10 holds only C9…G9
    /// sharp pitch classes relative to C: C# D# F# G# A#
    nonisolated static let sharpCols: Set<Int> = [1, 3, 6, 8, 10]
    /// note circle radius range: recognizable dot → 1.62 × slot diameter
    nonisolated static let radiusMin: CGFloat = 2
    nonisolated static let slotRatio: CGFloat = 0.81

    /// midi num → velocity 0…127, maintained by note on/off closures
    public private(set) var activeNotes: [Int: Float] = [:]
    /// 0 midi, 1 microphone — mirrors music node x
    public private(set) var source: Int = 0
    /// mic note-vs-noise sensitivity 0…1 — mirrors music node y
    public private(set) var sensitivity: Double = 0.35
    /// max simultaneous mic notes 1…8 — mirrors music node z
    public private(set) var polyphony: Int = 3

    /// magnitude floor for mic note detection — exponential over an
    /// expanded range: sens 0 admits only dominant bins (0.6), sens 1
    /// near-everything (0.005)
    public var fftThreshold: Float { Float(0.6 * pow(0.005 / 0.6, sensitivity)) }

    private var noteOn˚    : Flo?
    private var noteOff˚   : Flo?
    private var afterTouch˚: Flo?
    private var micInput˚  : Flo?

    override init(_ menuTree: MenuTree,
                  _ branchVm: BranchVm,
                  _ prevVm: NodeVm?,
                  _ runTypes: [LeafRunwayType]) {

        super.init(menuTree, branchVm, prevVm, runTypes)

        var root = menuTree.flo
        while let parent = root.parent { root = parent }
        noteOn˚     = root.findPath("midi.input.note.on")
        noteOff˚    = root.findPath("midi.input.note.off")
        afterTouch˚ = root.findPath("midi.input.afterTouch")
        micInput˚   = root.findPath("mic.input")

        // midi callbacks arrive off-main — hop before touching state
        noteOn˚?.addClosure { [weak self] flo, _ in
            let num  = Int((flo.val("num") ?? -1).rounded())
            let velo = Float(flo.val("velo") ?? 0)
            DebugLog { P("🎹 on \(num) v\(Int(velo))") }
            Task { @MainActor in self?.noteOn(num, velo) }
        }
        noteOff˚?.addClosure { [weak self] flo, _ in
            let num = Int((flo.val("num") ?? -1).rounded())
            DebugLog { P("🎹 off \(num)") }
            Task { @MainActor in self?.noteOff(num) }
        }
        // continuous loudness: poly aftertouch per num, channel pressure num 0
        afterTouch˚?.addClosure { [weak self] flo, _ in
            let num = Int((flo.val("num") ?? 0).rounded())
            let val = Float(flo.val("val") ?? 0)
            DebugLog { P("🎹 at \(num) v\(Int(val))") }
            Task { @MainActor in self?.afterTouch(num, val) }
        }
        readMusicScalars(menuTree.flo)
    }

    override public func touchLeaf(_: TouchState, _: Visitor) {} // native gestures
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { menuTree.flo.name }
    override public func syncVal(_: Visitor) {}
    /// live-input monitor pins the tree open (LeafGraphVm precedent)
    override public var disablesAutoFade: Bool { true }

    private func readMusicScalars(_ flo: Flo) {
        source = Int((flo.val("x") ?? 0).rounded())
        sensitivity = flo.val("y") ?? 0.35
        polyphony = max(1, min(8, Int((flo.val("z") ?? 3).rounded())))
    }

    /// external x y z change (peer/archive) re-syncs selector and sliders
    override public func updateFromFlo(_ flo: Flo, _ visit: Visitor) {
        guard !visit.wasHere(leafHash) else { return }
        readMusicScalars(flo)
        refreshView()
    }

    /// sensitivity slider 0…1 → music.y (flo-first, same-control)
    public func setSensitivity(_ norm: Double) {
        sensitivity = min(1, max(0, norm))
        syncMusicScalars()
    }
    /// polyphony slider 0…1 → music.z count 1…8
    public func setPolyphony(_ norm: Double) {
        polyphony = 1 + Int((min(1, max(0, norm)) * 7).rounded())
        syncMusicScalars()
    }

    func noteOn(_ num: Int, _ velo: Float) {
        guard (Self.noteLo...Self.noteHi).contains(num) else { return }
        if velo <= 0 { activeNotes.removeValue(forKey: num) } // running status off
        else         { activeNotes[num] = velo }
        refreshView()
    }
    func noteOff(_ num: Int) {
        activeNotes.removeValue(forKey: num)
        refreshView()
    }
    /// aftertouch reshapes held circles live: per-note, or all when num == 0
    func afterTouch(_ num: Int, _ val: Float) {
        if num > 0 {
            guard activeNotes[num] != nil else { return }
            activeNotes[num] = max(1, val)
        } else if !activeNotes.isEmpty {
            for key in activeNotes.keys { activeNotes[key] = max(1, val) }
        }
        refreshView()
    }

    /// full-width write of x y z — a partial setNameNums re-evaluates the
    /// unnamed components back to their defaults (source reset trap), and a
    /// bare .fire can run closures before the scalars settle: store silently
    /// first, then announce
    private func syncMusicScalars() {
        let nameNums: [(String, Double)] = [("x", Double(source)),
                                            ("y", sensitivity),
                                            ("z", Double(polyphony))]
        menuTree.flo.setNameNums(nameNums, .sneak, Visitor(0, .user))
        menuTree.flo.setNameNums(nameNums, .fire, Visitor(0, .user))
        refreshView()
    }

    /// radio tap: writes music.x (flo-first) and wakes the shared mic tap
    /// when needed; midi select never lowers the mic gate (tap is shared)
    public func setSource(_ newSource: Int) {
        guard newSource != source else { return }
        source = newSource
        syncMusicScalars()
        if newSource == 1, let micInput˚, (micInput˚.val("y") ?? 0) <= 0 {
            micInput˚.setNameNums([("y", 0.5), ("w", micInput˚.val("w") ?? 0)],
                                  .fire, Visitor(0, .user))
        }
    }

    /// grid slot for a midi note: (col, row) with row 0 at the BOTTOM
    nonisolated public static func colRow(_ num: Int) -> (col: Int, row: Int) {
        let index = num - noteLo
        return (index % cols, index / cols)
    }

    /// hue per input source — 0 midi, 1 mic; future stems extend the index
    public static func sourceColor(_ source: Int) -> Color {
        switch source {
        case 0  : return .cyan
        case 1  : return .green
        default : return Color(hue: Double((source - 2) % 6) / 6.0,
                               saturation: 0.8, brightness: 0.9)
        }
    }

    /// FFT bins → per-note velocities 0…127, gated by the sensitivity floor,
    /// scaled by the ABSOLUTE loudness gate (bins alone are per-buffer
    /// normalized — relative only), and capped to the strongest `maxNotes`.
    /// Engine default 44.1 kHz → nyquist 22050; 512 bins ≈ 43 Hz spacing
    /// (lowest octaves alias to their nearest bins)
    public static func fftNoteVelocities(_ bins: [Float],
                                         threshold: Float,
                                         maxNotes: Int,
                                         level: Float) -> [Int: Float] {
        guard level > 0, bins.count > 1 else { return [:] }
        let binHz = 22_050.0 / Double(bins.count)
        var notes = [Int: Float]()
        for (i, mag) in bins.enumerated() where mag > threshold {
            let freq = Double(i) * binHz
            guard freq > 20 else { continue }
            let note = Int((69 + 12 * log2(freq / 440)).rounded())
            guard (noteLo...noteHi).contains(note) else { continue }
            notes[note] = max(notes[note] ?? 0, mag * 127 * level)
        }
        guard notes.count > maxNotes else { return notes }
        let strongest = notes.sorted { $0.value > $1.value }.prefix(max(1, maxNotes))
        return Dictionary(uniqueKeysWithValues: Array(strongest))
    }
}
#endif
