#if !os(watchOS)
//  created by musesum on 8/7/26

import SwiftUI
import UIKit
import MuFlo

/// one colored run of a script row, in the row text's own character offsets
struct ScriptTok {
    let text: String
    let hue: ScriptHue
    let from: Int
    let upto: Int
    let space: Bool     /// whitespace, and so the break the wrap may take
}

/// Xcode "Customized Default (Dark)" token classes, as probed, restricted to
/// the ones Xcode actually reaches when it colors a `.flo.h` buffer — which it
/// opens as a C header. A C tokenizer claims literals and comments and leaves
/// every identifier, operator and mark plain, so the column does the same
enum ScriptHue: UInt8 {
    case plain      /// xcode.syntax.plain: names, edge ops, target paths, marks
    case quote      /// xcode.syntax.string: `"…"`
    case chars      /// xcode.syntax.character: `'…'` titles
    case digit      /// xcode.syntax.number: numbers, ranges, defaults
    case note       /// xcode.syntax.comment: `//` tails, the one italic class
}

/// one visual line: the tokens it draws, its own indent, and the character
/// span it covers, which is what the find tint is measured against
struct ScriptRun {
    let from: Int       /// first token index
    let upto: Int       /// one past the last token index
    let lead: CGFloat   /// continuation indent, zero on the first line
}

/// one row laid out at one column width; cached, because the wrap is measured.
/// The wrap owns the width, so a row reports only the height it takes
final class ScriptDraw {
    let toks: [ScriptTok]
    let runs: [ScriptRun]
    let plain: [AttributedString]   /// each line untinted, the common case
    let high: CGFloat               /// the row's whole height, the gap included

    init(_ toks: [ScriptTok],
         _ runs: [ScriptRun],
         _ plain: [AttributedString],
         _ high: CGFloat) {
        self.toks = toks
        self.runs = runs
        self.plain = plain
        self.high = high
    }
}

/// left column: the whole flo script, one row per node, indented by depth and
/// colored the way Xcode colors it. A row too wide for the column wraps, its
/// continuation landing left of the line's own open paren. A row with children
/// folds its whole subtree away and gives one level back
struct LeafGraphScriptView: View {

    @ObservedObject var leafVm: LeafGraphVm

    /// gesture reading, fixed once the touch has travelled far enough
    private enum ScriptSlide { case unread, scroll }

    @State private var slide = ScriptSlide.unread
    @State private var slideLast = CGFloat(0)   /// travel already spent scrolling
    @State private var shift = CGFloat(0)       /// scrolled distance, down only
    @State private var listing = false          /// options popover showing
    @State private var pinching = false         /// two fingers are on the column
    @State private var pinched = false          /// and one end already fired

    /// the column's own first responder, claimed by a touch on the rows and
    /// yielded to either field while it holds the caret
    @State private var keys = ScriptKeys()

    static let textSize = CGFloat(10)           /// row text, measured and drawn
    private static let rowGap = CGFloat(2)      /// between the stacked rows
    private static let levelSpan = CGFloat(9)   /// indent one level takes
    private static let markSpan = CGFloat(11)   /// disclosure gutter
    private static let markSlop = CGFloat(6)    /// gutter slack the fold still takes
    private static let padX = CGFloat(4)
    /// leading inset both bar backgrounds take. The NW and SW grab bands sweep
    /// a quarter arc about a center 18pt inside each corner, so nothing they
    /// reach lies past 18pt on the x axis; a background starting at 20 stands
    /// clear of both with 2pt to spare, and the bars keep their 4pt elsewhere
    static let barLead = CGFloat(20)
    static let readSpan = CGFloat(6)            /// travel before the drag scrolls
    static let pinchShut = CGFloat(0.8)         /// closing past this folds the tree
    static let pinchOpen = CGFloat(1.25)        /// opening past this drops every fold
    private static let turnSec = 0.25           /// disclosure turn, as the menu takes
    private static let wrapLeast = CGFloat(4)   /// glyphs a column wraps in at all
    private static let hangGlyphs = CGFloat(2)  /// indent a paren-less row hangs at
    private static let drawKeep = 8000          /// laid out rows kept before a reset

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    // MARK: - theme

    /// Dev's probed theme; the row background is the column's own fill, so the
    /// theme background sits behind it unpainted
    private static let hues: [ScriptHue: Color] = [
        .plain  : Color(red: 1, green: 1, blue: 1),
        .quote  : Color(red: 0.9891, green: 0.4156, blue: 0.3657),
        .chars  : Color(red: 0.5875, green: 0.5272, blue: 0.9595),
        .digit  : Color(red: 0.5875, green: 0.5272, blue: 0.9595),
        .note   : Color(red: 0.5480, green: 0.6112, blue: 0.6854)]

    static let fill = Color.white.opacity(0.06)         /// the column's own dark
    private static let litRow = Color.white.opacity(0.13)  /// selected row
    private static let litMark = Color.white.opacity(0.07) /// multi-selected row
    private static let litFind = Color.yellow.opacity(0.35) /// a find hit
    private static let litSel = Color.yellow.opacity(0.12) /// selection tint

    /// SFMono-Medium by name where the family is registered, and the system
    /// monospace at the same weight where it is not
    @MainActor private static let rowFont: UIFont =
    UIFont(name: "SFMono-Medium", size: textSize)
    ?? UIFont.monospacedSystemFont(ofSize: textSize, weight: .medium)

    @MainActor private static let bodyFont = Font(rowFont)

    /// the comment class is the one slanted run; a family without an italic
    /// face falls back to the synthesized slant
    @MainActor private static let noteFont: Font = {
        if let slant = rowFont.fontDescriptor.withSymbolicTraits(.traitItalic) {
            return Font(UIFont(descriptor: slant, size: textSize))
        }
        return Font(rowFont).italic()
    }()

    @MainActor static let lineHigh = ceil(rowFont.lineHeight)

    // MARK: - metrics

    @MainActor private static var spanCache = [String: CGFloat]()

    /// drawn width of one token, measured once per distinct text
    @MainActor private static func span(_ text: String) -> CGFloat {
        if let span = spanCache[text] { return span }
        let span = ceil((text as NSString)
            .size(withAttributes: [.font: rowFont]).width)
        spanCache[text] = span
        return span
    }

    @MainActor private static var drawCache = [String: ScriptDraw]()

    /// one row laid out at one width; the width and the wrap are part of the
    /// key, so a dragged column re-wraps, a restored one comes back to what it
    /// had, and the two wrap states keep their own runs. The comment option
    /// rides the key already, since dropping a comment changes `row.text`
    @MainActor static func draw(_ row: ScriptRow,
                                _ wide: CGFloat,
                                _ wrap: Bool) -> ScriptDraw {
        let wide = wide.isFinite ? max(0, wide) : 0
        let key = "\(Int(wide))|\(row.level)|\(wrap ? 1 : 0)|\(row.text)"
        if let made = drawCache[key] { return made }
        if drawCache.count > drawKeep { drawCache.removeAll() }
        let made = makeDraw(row, wide, wrap)
        drawCache[key] = made
        return made
    }

    /// the row's left gutter: its hierarchy indent, the disclosure box, the pads
    @MainActor private static func rowLead(_ level: Int) -> CGFloat {
        CGFloat(level) * levelSpan + markSpan + 2 * padX
    }

    // MARK: - wrap

    /// greedy pack against measured token widths. The first line runs the whole
    /// column; every line after it is indented one glyph left of the row's own
    /// open paren, so a wrapped argument lands under the name that opened it
    @MainActor private static func makeDraw(_ row: ScriptRow,
                                            _ wide: CGFloat,
                                            _ wrap: Bool) -> ScriptDraw {
        let toks = tokens(row.text)
        let lead = rowLead(row.level)
        let room = wide - lead
        let glyph = span("0")
        guard !toks.isEmpty else {
            return ScriptDraw([], [], [], lineHigh + rowGap)
        }
        // wrap off, or too narrow to break in: one line, and the column's own
        // clip carries the overrun, so a long row loses its tail and the
        // column still pans on one axis
        guard wrap, room >= glyph * wrapLeast else {
            let runs = [ScriptRun(from: 0, upto: toks.count, lead: 0)]
            return ScriptDraw(toks, runs, [lineText(toks, runs[0], nil)],
                              lineHigh + rowGap)
        }
        var runs = [ScriptRun]()
        var at = 0
        var hang = CGFloat(0)
        while at < toks.count {
            let mine = runs.isEmpty ? 0 : hang
            if !runs.isEmpty {
                while at < toks.count, toks[at].space { at += 1 }
            }
            guard at < toks.count else { break }
            let from = at
            var x = CGFloat(0)
            while at < toks.count {
                let step = span(toks[at].text)
                if x > 0, !toks[at].space, x + step > room - mine { break }
                x += step
                at += 1
            }
            if at == from {         // one token wider than the whole line
                x = span(toks[from].text)
                at = from + 1
            }
            runs.append(ScriptRun(from: from, upto: at, lead: mine))
            if runs.count == 1 { hang = hangLead(toks, from, at, glyph, room) }
        }
        let plain = runs.map { lineText(toks, $0, nil) }
        return ScriptDraw(toks, runs, plain,
                          CGFloat(runs.count) * lineHigh + rowGap)
    }

    /// the continuation indent: one glyph left of the first open paren on the
    /// opening line, so `sym "paintbrush"` wraps to the column left of `(`.
    /// A row that opens no paren hangs at a plain two glyphs instead
    @MainActor private static func hangLead(_ toks: [ScriptTok],
                                            _ from: Int,
                                            _ upto: Int,
                                            _ glyph: CGFloat,
                                            _ room: CGFloat) -> CGFloat {
        let most = max(0, room - glyph * wrapLeast)
        var x = CGFloat(0)
        for at in from ..< upto {
            if toks[at].text == "(" { return min(most, max(0, x - glyph)) }
            x += span(toks[at].text)
        }
        return min(most, glyph * hangGlyphs)
    }

    // MARK: - tokens

    /// every mark an edge operator is built from. `EdgeOptions.script` emits the
    /// explicit `<>` `<-` `->` `^-` and the implicit `<`/`>` wrapped around one
    /// of `◇ ⟡ : ^`. The run is kept whole for the wrap alone — it draws plain,
    /// the way a C tokenizer leaves an operator — so `<>` never breaks a line
    static let edgeMarks = Set<Character>("<>-^!◇⟡:")

    /// one row's text as colored runs, the way Xcode tokenizes a C header:
    /// `"…"` is a string, `'…'` a character, a digit run a number, a `//` tail a
    /// comment, and every identifier, operator, target path and mark is plain
    static func tokens(_ text: String) -> [ScriptTok] {
        var toks = [ScriptTok]()
        let marks = Array(text)
        var at = 0

        func add(_ hue: ScriptHue, _ from: Int, _ upto: Int, _ space: Bool = false) {
            toks.append(ScriptTok(text: String(marks[from ..< upto]),
                                  hue: hue, from: from, upto: upto, space: space))
        }
        func isGap(_ at: Int) -> Bool {
            at < marks.count && (marks[at] == " " || marks[at] == "\t")
        }
        while at < marks.count {
            let mark = marks[at]
            if isGap(at) {
                var to = at
                while isGap(to) { to += 1 }
                add(.plain, at, to, true)
                at = to

            } else if mark == "/", at + 1 < marks.count, marks[at + 1] == "/" {
                // the comment tail runs to the end, one token per word so a
                // long note wraps the way any other run does
                var to = at
                while to < marks.count {
                    if isGap(to) {
                        var gap = to
                        while isGap(gap) { gap += 1 }
                        add(.plain, to, gap, true)
                        to = gap
                    } else {
                        var run = to
                        while run < marks.count, !isGap(run) { run += 1 }
                        add(.note, to, run)
                        to = run
                    }
                }
                at = marks.count

            } else if mark == "\"" || mark == "'" {
                var to = at + 1
                while to < marks.count {
                    if marks[to] == "\\" { to = min(marks.count, to + 2); continue }
                    if marks[to] == mark { to += 1; break }
                    to += 1
                }
                add(mark == "\"" ? .quote : .chars, at, min(to, marks.count))
                at = min(to, marks.count)

            } else if mark.isNumber
                        || (mark == "-" && at + 1 < marks.count
                            && marks[at + 1].isNumber) {
                var to = at + 1
                while to < marks.count, marks[to].isNumber
                        || marks[to] == "." || marks[to] == "_"
                        || marks[to] == "…" { to += 1 }
                add(.digit, at, to)
                at = to

            } else if mark.isLetter || mark == "_" {
                var to = at + 1
                while to < marks.count, marks[to].isLetter
                        || marks[to].isNumber || marks[to] == "_" { to += 1 }
                add(.plain, at, to)
                at = to

            } else if edgeMarks.contains(mark) {
                var to = at
                while to < marks.count, edgeMarks.contains(marks[to]) { to += 1 }
                add(.plain, at, to)
                at = to

            } else {
                add(.plain, at, at + 1)
                at += 1
            }
        }
        return toks
    }

    // MARK: - text

    /// one line's attributed text; a row carrying find hits is rebuilt with the
    /// tint, and every other row draws the run it was laid out with
    @MainActor private static func lineText(_ toks: [ScriptTok],
                                            _ run: ScriptRun,
                                            _ spans: [Range<Int>]?) -> AttributedString {
        var out = AttributedString()
        for at in run.from ..< min(run.upto, toks.count) {
            let tok = toks[at]
            guard let spans, !spans.isEmpty else {
                out += piece(tok.text, tok.hue, false)
                continue
            }
            // split the token where the hit ranges start and stop
            let marks = Array(tok.text)
            var from = tok.from
            while from < tok.upto {
                let lit = spans.contains { $0.contains(from) }
                var upto = from + 1
                while upto < tok.upto,
                      spans.contains(where: { $0.contains(upto) }) == lit {
                    upto += 1
                }
                out += piece(String(marks[(from - tok.from) ..< (upto - tok.from)]),
                             tok.hue, lit)
                from = upto
            }
        }
        return out
    }

    @MainActor private static func piece(_ text: String,
                                         _ hue: ScriptHue,
                                         _ lit: Bool) -> AttributedString {
        var out = AttributedString(text)
        out.foregroundColor = hues[hue] ?? .white
        out.font = hue == .note ? noteFont : bodyFont
        if lit { out.backgroundColor = litFind }
        return out
    }

    /// running row tops, the last entry the whole run's height
    @MainActor private static func tops(_ draws: [ScriptDraw]) -> [CGFloat] {
        var tops = [CGFloat(0)]
        var y = CGFloat(0)
        for draw in draws {
            y += draw.high
            tops.append(y)
        }
        return tops
    }

    // MARK: - body

    var body: some View {
        // the options list floats over the column, above its own dismiss
        // catcher, the way the side column's search history does
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                ScriptFindView(leafVm, keys)
                GeometryReader { geo in
                    scriptView(geo)
                }
                ScriptSiftView(leafVm, keys, $listing)
            }
            if listing {
                Color.white.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { listing = false }
                ScriptOptsView(leafVm)
                    .padding(.leading, 4)
                    .padding(.bottom, ScriptSiftView.rowSpan + 8)
            }
        }
        .background(RoundedRectangle(cornerRadius: Menu.cornerRadius)
            .fill(Self.fill))
        .onAppear {
            leafVm.fillScript()
            leafVm.scriptKeys = keys    // a graph tap reads its modifiers here
        }
    }

    /// the rows themselves, laid out at the column's own width. The wrap owns
    /// the width, so the column pans on one axis only; row heights are
    /// measured, so the scroll extent and every hit test read the same run
    private func scriptView(_ geo: GeometryProxy) -> some View {
        let rows = leafVm.scriptRows
        let draws = rows.map { Self.draw($0, geo.size.width, leafVm.scriptWrap) }
        let tops = Self.tops(draws)
        let tall = tops.last ?? 0
        // a fold can shrink the run under a standing scroll, so the offset
        // the column draws at is the clamped one, and the hit test reads it
        let most = max(0, tall - geo.size.height)
        let spot = min(shift, most)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { at, row in
                rowView(row, draws[at], leafVm.scriptSpans[at])
            }
        }
        .frame(width: geo.size.width, alignment: .leading)
        .offset(y: -spot)
        .frame(width: geo.size.width, height: geo.size.height,
               alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
        .gesture(touchScript(most, spot, tops))
        // composed, not chained: `simultaneousGesture` gives the pinch its own
        // recognizer beside the drag's, so the scroll and the row taps keep
        // reading every one-finger touch exactly as they did
        .simultaneousGesture(pinchScript())
        // the responder rides behind the rows, taking no touch of its own
        .background(ScriptKeysView(keys, walkScript)
            .frame(width: 1, height: 1)
            .allowsHitTesting(false))
        .onChange(of: leafVm.scriptAt) {
            let at = leafVm.scriptAt
            guard at >= 0, at < tops.count - 1 else { return }
            shift = min(most, max(0, tops[at] - Self.lineHigh))
        }
        .onChange(of: leafVm.scriptPicked) {
            showPicked(rows, tops, most, geo.size.height)
        }
    }

    // MARK: - keyboard

    /// one arrow arriving from the column's own first responder. Option takes
    /// each key to its far end: the ends of the run, and the whole tree's folds
    private func walkScript(_ arrow: ScriptArrow, _ far: Bool) {
        switch arrow {
        case .up:
            if far { leafVm.endScript(false) } else { leafVm.stepScript(false) }
        case .down:
            if far { leafVm.endScript(true) } else { leafVm.stepScript(true) }
        case .left:
            if far { leafVm.foldAllScript() } else { leafVm.foldScript() }
        case .right:
            if far { leafVm.expandAllScript() } else { leafVm.openScript() }
        }
    }

    /// the selected row brought just inside the column, whether a key, a row
    /// tap or a graph tap moved it. A row already standing keeps the scroll
    private func showPicked(_ rows: [ScriptRow],
                            _ tops: [CGFloat],
                            _ most: CGFloat,
                            _ tall: CGFloat) {
        let id = leafVm.scriptPicked
        guard id >= 0,
              let at = rows.firstIndex(where: { $0.id == id }),
              at + 1 < tops.count
        else { return }
        // a fold can leave `shift` past the run, so the reveal reads the same
        // clamped offset the column draws at
        let now = min(shift, most)
        var next = now
        if tops[at] < now {
            next = tops[at]
        } else if tops[at + 1] > now + tall {
            next = tops[at + 1] - tall
        }
        shift = min(most, max(0, next))
    }

    /// one script line; a childless node keeps the gutter so the text lines up
    private func rowView(_ row: ScriptRow,
                         _ draw: ScriptDraw,
                         _ spans: [Range<Int>]?) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Image(systemName: "chevron.right")
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(.white.opacity(row.shown ? 1 : 0.25))
                .rotationEffect(.degrees(row.shown ? 90 : 0))
                .animation(.easeInOut(duration: Self.turnSec), value: row.shown)
                .frame(width: Self.markSpan, height: Self.lineHigh)
                .opacity(row.hasChildren ? 1 : 0)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(draw.runs.indices, id: \.self) { at in
                    Text(spans == nil
                         ? draw.plain[at]
                         : Self.lineText(draw.toks, draw.runs[at], spans))
                    .frame(height: Self.lineHigh, alignment: .leading)
                    .fixedSize()
                    .padding(.leading, draw.runs[at].lead)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, CGFloat(row.level) * Self.levelSpan + Self.padX)
        .frame(height: draw.high, alignment: .topLeading)
        .background(Self.rowFill(leafVm.scriptPicked == row.id,
                                 leafVm.scriptMarks.contains(row.id)))
    }

    /// the pick reads over the multi-selection, so the anchor of a gathered set
    /// still stands out from the rest of it. Both take the one yellow tint the
    /// page lights the same nodes with, laid under the row's own tokens and
    /// well under the find hit, which is the same yellow at its full strength
    private static func rowFill(_ picked: Bool, _ marked: Bool) -> some View {
        ZStack {
            picked ? litRow : marked ? litMark : Color.clear
            if picked || marked { litSel }
        }
    }

    /// one gesture, one hit test: a drag past the read span slides the column
    /// down its one axis, a touch alone reads the row under it. Travel on
    /// either axis still spends the touch, so a sideways smear pans nothing
    /// and selects nothing rather than firing a row it was never aimed at
    private func touchScript(_ most: CGFloat,
                             _ spot: CGFloat,
                             _ tops: [CGFloat]) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                // a pinch moves its own first finger; the drag reads none of
                // that travel, so the column neither scrolls nor selects under one
                guard !pinching else { return }
                let step = drag.translation
                if slide == .unread,
                   max(abs(step.width), abs(step.height)) >= Self.readSpan {
                    slide = .scroll
                }
                if slide == .scroll {
                    let dy = step.height - slideLast
                    shift = min(most, max(0, shift - dy))
                }
                slideLast = step.height
            }
            .onEnded { drag in
                // any touch on the column hands it the keys, whether it landed
                // on a row, past the last one, or spent itself scrolling
                keys.claim()
                if !pinching, slide == .unread {
                    touchRow(drag.location, spot, tops)
                }
                slide = .unread
                slideLast = 0
            }
    }

    /// pinch over the column, carrying the two ends Option-left and
    /// Option-right already reach: closing past `pinchShut` runs the same
    /// `foldAllScript` the far-left key runs, and opening past `pinchOpen` the
    /// same `expandAllScript` the far-right key runs — one endpoint each, not
    /// a second spelling of either. `pinched` latches the fire for the length
    /// of the gesture, so a pinch that goes on closing folds once. Both flags
    /// drop on the next turn rather than in this one, the way `claimKeys`
    /// settles its want, so the drag ending in the same turn still reads the
    /// touch as spent and fires no row under the lifting fingers
    private func pinchScript() -> some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                pinching = true
                guard !pinched else { return }
                if scale <= Self.pinchShut {
                    pinched = true
                    leafVm.foldAllScript()
                } else if scale >= Self.pinchOpen {
                    pinched = true
                    leafVm.expandAllScript()
                }
            }
            .onEnded { _ in
                Task { @MainActor in
                    pinching = false
                    pinched = false
                }
            }
    }

    /// the row under the touch, in the scrolled column's own space. The
    /// disclosure gutter folds the subtree; the body beyond it selects the node
    private func touchRow(_ point: CGPoint, _ spot: CGFloat, _ tops: [CGFloat]) {
        let rows = leafVm.scriptRows
        let y = point.y + spot
        guard y >= 0, y < tops.last ?? 0 else { return }
        var at = 0
        while at + 1 < tops.count - 1, tops[at + 1] <= y { at += 1 }
        guard at < rows.count else { return }
        let row = rows[at]
        let mark = CGFloat(row.level) * Self.levelSpan
        + Self.padX + Self.markSpan + Self.markSlop
        switch Self.readTouch(keys.mods, row.hasChildren && point.x <= mark) {
        case .fold : leafVm.toggleScript(row.id)
        case .flip : leafVm.flipScript(row.id)
        case .span : leafVm.spanScript(row.id)
        case .pick : leafVm.pickScript(row.id)
        }
    }

    /// what a row touch means: the disclosure gutter folds, and past it the
    /// modifiers the hardware keyboard holds decide. Command gathers the row on
    /// its own, shift takes the range from the anchor, and a bare touch picks
    /// the way it always has. Kept apart from the hit test so the table can be
    /// read straight, which is the only way a modifier is provable off-device
    static func readTouch(_ mods: UIKeyModifierFlags,
                          _ gutter: Bool) -> ScriptTouch {
        if gutter { return .fold }
        if mods.contains(.command) { return .flip }
        if mods.contains(.shift) { return .span }
        return .pick
    }
}

/// what one row touch does
enum ScriptTouch { case fold, pick, flip, span }

// MARK: - first responder

/// the four keys the column walks by
enum ScriptArrow: CaseIterable {
    case up, down, left, right

    var input: String {
        switch self {
        case .up    : return UIKeyCommand.inputUpArrow
        case .down  : return UIKeyCommand.inputDownArrow
        case .left  : return UIKeyCommand.inputLeftArrow
        case .right : return UIKeyCommand.inputRightArrow
        }
    }
}

/// the column's keyboard claim, shared by the row touch and the two fields.
/// Each of them owns its own call; the box only forwards to the responder
@MainActor final class ScriptKeys {

    fileprivate weak var view: ScriptKeysUIView?

    /// the modifiers the hardware keyboard is holding as the touch lands. The
    /// responder is the only place they arrive, so the box reads them from it
    /// and holds its own when it has none — which is also the seam a test
    /// drives, since the simulator cannot inject a modifier with a touch
    var mods: UIKeyModifierFlags {
        get { view?.mods ?? held }
        set { held = newValue; view?.mods = newValue }
    }

    private var held = UIKeyModifierFlags()

    /// a touch on the rows takes the arrows back
    func claim() { view?.claimKeys(true) }

    /// a field taking the caret gives them up for as long as it holds it
    func yield() { view?.claimKeys(false) }
}

/// the arrow keys, taken through the responder chain rather than SwiftUI focus.
/// iPadOS hands SwiftUI focus to a non-text view only while Full Keyboard
/// Access is on, so `focusable()` + `onKeyPress` never fired on a stock device;
/// a first responder vending `keyCommands` is the path that does not gate on it
final class ScriptKeysUIView: UIView {

    /// set by the representable; the column owns what each arrow means
    var walk: ((ScriptArrow, Bool) -> Void)?

    /// the modifiers standing right now. A `UIKeyCommand` only reports them on
    /// the key it fired for, and a row touch fires no key at all, so the plain
    /// press stream is what a touch reads its modifiers from
    var mods = UIKeyModifierFlags()

    private var want = false

    override var canBecomeFirstResponder: Bool { true }

    override func pressesBegan(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        mods = Self.readMods(presses, event, mods)
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        mods = Self.readMods(presses, event, [])
        super.pressesEnded(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>,
                                   with event: UIPressesEvent?) {
        mods = []
        super.pressesCancelled(presses, with: event)
    }

    /// the event carries the whole standing set where it has one; a press
    /// without an event falls back to the key's own flags, and to `spare`
    private static func readMods(_ presses: Set<UIPress>,
                                 _ event: UIPressesEvent?,
                                 _ spare: UIKeyModifierFlags) -> UIKeyModifierFlags {
        if let event { return event.modifierFlags }
        var flags = spare
        for press in presses {
            if let key = press.key { flags.formUnion(key.modifierFlags) }
        }
        return flags
    }

    /// the plain arrow and its Option variant, one command each. Priority over
    /// the system keeps the focus engine from eating them first
    override var keyCommands: [UIKeyCommand]? {
        var list = [UIKeyCommand]()
        for arrow in ScriptArrow.allCases {
            for flags in [UIKeyModifierFlags(), .alternate] {
                let command = UIKeyCommand(input: arrow.input,
                                           modifierFlags: flags,
                                           action: #selector(walkKey(_:)))
                command.wantsPriorityOverSystemBehavior = true
                list.append(command)
            }
        }
        return list
    }

    @objc private func walkKey(_ sender: UIKeyCommand) {
        guard let arrow = ScriptArrow.allCases
            .first(where: { $0.input == sender.input })
        else { return }
        walk?(arrow, sender.modifierFlags.contains(.alternate))
    }

    /// the claim settles on the next turn, so a field taking the caret in the
    /// same turn is not out-raced, and the standing want is what gets applied
    func claimKeys(_ on: Bool) {
        want = on
        Task { @MainActor [weak self] in
            guard let self else { return }
            if want, !isFirstResponder, window != nil {
                _ = becomeFirstResponder()
            } else if !want, isFirstResponder {
                _ = resignFirstResponder()
            }
        }
    }
}

/// zero-touch host for the column's first responder
private struct ScriptKeysView: UIViewRepresentable {

    let keys: ScriptKeys
    let walk: (ScriptArrow, Bool) -> Void

    init(_ keys: ScriptKeys, _ walk: @escaping (ScriptArrow, Bool) -> Void) {
        self.keys = keys
        self.walk = walk
    }

    func makeUIView(context: Context) -> ScriptKeysUIView {
        let view = ScriptKeysUIView()
        view.walk = walk
        keys.view = view
        return view
    }

    func updateUIView(_ view: ScriptKeysUIView, context: Context) {
        view.walk = walk
        keys.view = view
    }

    static func dismantleUIView(_ view: ScriptKeysUIView, coordinator: ()) {
        view.claimKeys(false)
    }
}

// MARK: - options

/// the filter bar's own options: the comment tails the rows carry, the wrap,
/// whether a parent row gathers its subtree, whether a verified fan draws as
/// its shorthand, and whether the selection posts its own wires beside it.
/// All five live where they stand — none is written anywhere
private struct ScriptOptsView: View {

    @ObservedObject var leafVm: LeafGraphVm

    private static let rowSpan = CGFloat(26)

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            check("Comments", leafVm.scriptNotes) { leafVm.scriptNotes.toggle() }
            rule
            check("Wrap", leafVm.scriptWrap) { leafVm.scriptWrap.toggle() }
            rule
            check("Group", leafVm.scriptGroup) { leafVm.scriptGroup.toggle() }
            rule
            check("Compact", leafVm.scriptCompact) { leafVm.scriptCompact.toggle() }
            rule
            check("Edges", leafVm.scriptEdges) { leafVm.scriptEdges.toggle() }
        }
        .frame(width: 108)
        .background(RoundedRectangle(cornerRadius: 6)
            .fill(Color(white: 0.17))
            .shadow(radius: 4))
    }

    private var rule: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }

    private func check(_ title: String,
                       _ on: Bool,
                       _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            HStack(spacing: 5) {
                Image(systemName: on ? "checkmark.square.fill" : "square")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(on ? 0.9 : 0.4))
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: Self.rowSpan)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// script column top: the Xcode find bar, run over the row text. Every hit is
/// tinted where it sits, the count stands beside the field, and the return key
/// walks the hits, scrolling the column to each one
private struct ScriptFindView: View {

    @ObservedObject var leafVm: LeafGraphVm
    let keys: ScriptKeys
    @FocusState private var editing: Bool
    @State private var text = ""
    @State private var pending: Task<Void, Never>?

    static let rowSpan = CGFloat(24)
    private static let runDelay = UInt64(200)   /// keystroke settles into a query

    init(_ leafVm: LeafGraphVm, _ keys: ScriptKeys) {
        self.leafVm = leafVm
        self.keys = keys
    }

    private func findSoon(_ delay: UInt64) {
        pending?.cancel()
        let pattern = text
        pending = Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay * 1_000_000)
            }
            if Task.isCancelled { return }
            leafVm.scriptFind = pattern
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10))
                .foregroundColor(.gray)
            TextField("find", text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .focused($editing)
                .submitLabel(.next)
                .onSubmit {
                    // the standing pattern walks its hits; a fresh one runs and
                    // lands on the first, so the return key never doubles back
                    pending?.cancel()
                    if leafVm.scriptFind == text {
                        leafVm.nextFound()
                    } else {
                        leafVm.scriptFind = text
                    }
                }
                .onChange(of: text) { findSoon(Self.runDelay) }
            if !text.isEmpty {
                Text("\(leafVm.scriptFound)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .fixedSize()
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 5)
        .frame(height: Self.rowSpan)
        .background(RoundedRectangle(cornerRadius: 5)
            .fill(Color.white.opacity(0.12)))
        // the background itself is inset past the NW grab band, so no part of
        // the bar answers a touch the corner handle is also reading
        .padding(.vertical, 4)
        .padding(.trailing, 4)
        .padding(.leading, LeafGraphScriptView.barLead)
        .onChange(of: editing) {
            NextFrame.shared.pause = $1
            if $1 { keys.yield() }  // the caret takes the arrows with it
        }
        .onDisappear { NextFrame.shared.pause = false }
    }
}

/// script column bottom: the filter bar, run over node names. A match keeps the
/// chain above it, the way the Xcode filter bar keeps a hit in context, and the
/// field takes MuPar path notation as readily as a bare regex
private struct ScriptSiftView: View {

    @ObservedObject var leafVm: LeafGraphVm
    let keys: ScriptKeys
    @Binding var listing: Bool
    @FocusState private var editing: Bool
    @State private var text = ""
    @State private var pending: Task<Void, Never>?

    static let rowSpan = CGFloat(24)
    private static let runDelay = UInt64(250)

    init(_ leafVm: LeafGraphVm,
         _ keys: ScriptKeys,
         _ listing: Binding<Bool>) {
        self.leafVm = leafVm
        self.keys = keys
        self._listing = listing
    }

    private func siftSoon(_ delay: UInt64) {
        pending?.cancel()
        let pattern = text
        pending = Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay * 1_000_000)
            }
            if Task.isCancelled { return }
            leafVm.scriptSift = pattern
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            // the bar's own glyph, opening the two display options; the bar
            // background now carries the whole clearance, so the glyph sits at
            // the bar's own edge like the find bar's magnifier
            Button {
                listing.toggle()
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 10))
                    .foregroundColor(listing ? .white : .gray)
                    .frame(width: 14, height: Self.rowSpan - 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            TextField("filter", text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .focused($editing)
                .onSubmit { siftSoon(0) }
                .onChange(of: text) { siftSoon(Self.runDelay) }
            if !text.isEmpty {
                Text("\(leafVm.scriptRows.count)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .fixedSize()
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 5)
        .frame(height: Self.rowSpan)
        .background(RoundedRectangle(cornerRadius: 5)
            .fill(Color.white.opacity(0.12)))
        // the same inset the find bar takes, against the SW band
        .padding(.vertical, 4)
        .padding(.trailing, 4)
        .padding(.leading, LeafGraphScriptView.barLead)
        .onChange(of: editing) {
            NextFrame.shared.pause = $1
            if $1 { keys.yield() }  // the caret takes the arrows with it
        }
        .onDisappear { NextFrame.shared.pause = false }
    }
}
#endif
