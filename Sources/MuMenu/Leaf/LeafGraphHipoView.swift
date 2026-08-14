#if !os(watchOS)
//  created by musesum on 8/6/26

import SwiftUI
import UIKit

/// bottom card under the page: the focused node centered, the nodes feeding it
/// in columns to the left, the nodes it feeds in columns to the right
struct LeafGraphHipoView: View {

    @ObservedObject var leafVm: LeafGraphVm

    /// gesture reading, fixed once the touch has travelled far enough
    private enum HipoSlide { case unread, sweep, recenter, scroll }

    @State private var slide = HipoSlide.unread
    @State private var slideLast = CGFloat(0)   /// travel already spent scrolling
    @State private var scrollAt = [Int: CGFloat]()

    private static let gapWide = CGFloat(16)  /// chevron plus its spacing
    private static let gapTight = CGFloat(10) /// the same, once the columns crowd
    private static let colLeast = CGFloat(44) /// narrowest column a chip still reads in
    private static let rowGap = CGFloat(3)    /// between the stacked chip rows
    private static let gapLeast = CGFloat(1)  /// tightest gap a near fit squeezes to
    private static let padLeast = CGFloat(1)  /// tightest capsule padding it takes
    private static let readSpan = CGFloat(10) /// travel before the axis is read
    private static let axisRatio = CGFloat(1.5)
    private static let fitSlack = CGFloat(2)  /// centering yields near the brim
    private static let fitNear = CGFloat(8)   /// overrun a near fit squeezes away

    /// compaction floors, past the near fit. The gap holds at 1pt because
    /// `ChipFlow` spends the one gap on both axes: a zero gap abuts two capsules
    /// side by side, and two chips of one tint read as one
    private static let gapPack = CGFloat(1)
    private static let padPack = CGFloat(0.5) /// a capsule down to a hairline ring
    private static let gapStep = CGFloat(1)   /// the ladder the gap walks down
    private static let sizeStep = CGFloat(0.5)/// and the one the chip type walks

    static let chipSize = CGFloat(11)         /// chip text, measured and drawn
    /// the smallest chip type a compacted column draws. The card starts at 11pt,
    /// the size iOS gives its own smallest text style, and 8pt is three steps
    /// under it: a 0.727 scale, the last step whose x-height still resolves at
    /// arm's length on a 2x screen. Only a column still overrunning here scrolls
    static let sizeLeast = CGFloat(8)
    static let chipPadX = CGFloat(6)
    static let chipPadY = CGFloat(2)
    static let cardInset = CGFloat(2)         /// gap between the page and the card
    /// stands for the ancestors a truncated lineage dropped; no node carries a
    /// negative id, so a touch on it reaches `centerNodeHipo`'s own guard
    private static let dadMark = -2

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    /// one rendered column, sized for this card
    private struct HipoCol: Identifiable {
        let id: Int             /// signed level, 0 for the center
        let chips: [HipoChip]
        let kids: [HipoChip]    /// center column only: children under the focus
        let span: CGFloat       /// allocated width
        let gap: CGFloat        /// gap its rows take, squeezed on a near fit
        let padY: CGFloat       /// capsule padding, squeezed with the gap
        let size: CGFloat       /// chip type, scaled down when compaction asks
        let fits: Bool          /// stands centered, with nothing to scroll
    }

    /// the columns and where their run starts inside the card
    private struct HipoRow {
        let cols: [HipoCol]
        let start: CGFloat      /// empty card left of the first column
    }

    // MARK: - metrics

    /// one measured capsule: a name, at a weight, at a chip type size
    private struct ChipKey: Hashable {
        let name: String
        let bold: Bool
        let size: CGFloat
    }

    @MainActor private static var chipCache = [ChipKey: CGFloat]()
    @MainActor private static var lineCache = [CGFloat: CGFloat]()

    /// the chip font's line box at one type size, measured once
    @MainActor private static func chipLineHigh(_ size: CGFloat) -> CGFloat {
        if let high = lineCache[size] { return high }
        let high = UIFont.systemFont(ofSize: size).lineHeight
        lineCache[size] = high
        return high
    }

    /// the line box the card is dimensioned on, the height every chip row is
    /// built on before compaction
    @MainActor private static var chipLine: CGFloat { chipLineHigh(chipSize) }

    /// one chip row: that line box plus the capsule padding
    @MainActor private static var chipHigh: CGFloat { chipLine + 2 * chipPadY }

    /// the same row, on the padding and type a squeezed column draws with
    @MainActor private static func rowHigh(_ padY: CGFloat,
                                           _ size: CGFloat = chipSize) -> CGFloat {
        chipLineHigh(size) + 2 * padY
    }

    /// the capsule's own side padding, held in proportion as the type scales
    static func chipPad(_ size: CGFloat) -> CGFloat {
        chipPadX * size / chipSize
    }

    /// capsule width for a name, from the font the chip draws with
    @MainActor static func chipSpan(_ name: String,
                                    _ bold: Bool,
                                    _ size: CGFloat = chipSize) -> CGFloat {
        let key = ChipKey(name: name, bold: bold, size: size)
        if let span = chipCache[key] { return span }
        let font = UIFont.systemFont(ofSize: size,
                                     weight: bold ? .semibold : .regular)
        let text = (name as NSString).size(withAttributes: [.font: font]).width
        let span = ceil(text) + 2 * chipPad(size)
        chipCache[key] = span
        return span
    }

    /// a crowded card buys its columns from the chevron gaps
    private static func gapSpan(_ cols: Int) -> CGFloat {
        cols > 5 ? gapTight : gapWide
    }

    /// chip rows the card shows at once
    private static func rowCount(_ high: CGFloat) -> Int {
        max(1, Int((high + rowGap) / (chipHigh + rowGap)))
    }

    /// the near-square grid a run of chips packs into: the columns come from the
    /// ceiling of the square root, the rows from the count spread over them, and
    /// the pair is oriented so the rows are the longer side.
    /// 4 -> 2x2, 7 -> 3x3, 12 -> 4x3, 20 -> 5x4, 32 -> 6x6
    static func gridSlots(_ count: Int) -> (rows: Int, cols: Int) {
        guard count > 1 else { return (1, 1) }
        let cols = Int(ceil(Double(count).squareRoot()))
        let rows = Int(ceil(Double(count) / Double(cols)))
        return rows >= cols ? (rows, cols) : (cols, rows)
    }

    /// rows a column aims for: its own grid, and never more than the card can
    /// show. Fewer rows than the grid asks for only ever costs width, and the
    /// card's room is the harder bound, so the two meet at a minimum
    @MainActor private static func gridRows(_ count: Int,
                                            _ rows: Int) -> Int {
        min(gridSlots(count).rows, max(1, rows))
    }

    /// width a column wants: the narrowest that wraps its chips into the grid's
    /// own row count, floored by its widest chip. A run laid out this way stands
    /// N rows by M columns rather than single file or in one long strip.
    /// The center column grids its lineage and its kid band, on the rows its
    /// focus leaves
    @MainActor private static func colNeed(_ level: Int,
                                           _ chips: [HipoChip],
                                           _ kids: [HipoChip],
                                           _ rows: Int) -> CGFloat {
        let kidW = kidWide(kids, chipSize)
        let wide = chipWide(level, chips, chipSize) + kidW
        guard let widest = wide.max() else { return colLeast }
        let flow = flowWide(level, chips, kids, chipSize)
        let room = rows - (midSplit(level, chips, kids) ? 1 : 0)
        let grid = gridRows(flow.count + kidW.count, room)
        return max(widest, spanFor(flow, kidW, grid, rowGap))
    }

    /// rows measured capsule widths wrap into, the way ChipFlow wraps
    private static func rowsIn(_ wide: [CGFloat],
                               _ span: CGFloat,
                               _ gap: CGFloat) -> Int {
        var x = CGFloat(0), rows = 1
        for one in wide {
            let fit = min(one, span)
            if x > 0, x + fit > span { rows += 1; x = 0 }
            x += fit + gap
        }
        return rows
    }

    /// only the focus capsule draws bold; the lineage above it reads as
    /// ordinary chips, so it measures as ordinary chips
    private static func chipBold(_ level: Int, _ at: Int, _ count: Int) -> Bool {
        level == 0 && at == count - 1
    }

    /// the column's capsules, measured at one chip type size
    @MainActor private static func chipWide(_ level: Int,
                                            _ chips: [HipoChip],
                                            _ size: CGFloat) -> [CGFloat] {
        chips.indices.map {
            chipSpan(chips[$0].name, chipBold(level, $0, chips.count), size)
        }
    }

    /// the kid band's capsules; a kid is never the focus, so never bold
    @MainActor private static func kidWide(_ kids: [HipoChip],
                                           _ size: CGFloat) -> [CGFloat] {
        kids.map { chipSpan($0.name, false, size) }
    }

    /// the center column draws its lineage above the focus and its kids under
    /// it, so the focus keeps the row of its own and never joins a wrap
    private static func midSplit(_ level: Int,
                                 _ chips: [HipoChip],
                                 _ kids: [HipoChip]) -> Bool {
        level == 0 && (chips.count > 1 || !kids.isEmpty)
    }

    /// the capsules a column's flow wraps: every chip, less the focus the
    /// center column holds out
    @MainActor private static func flowWide(_ level: Int,
                                            _ chips: [HipoChip],
                                            _ kids: [HipoChip],
                                            _ size: CGFloat) -> [CGFloat] {
        let wide = chipWide(level, chips, size)
        return midSplit(level, chips, kids) ? Array(wide.dropLast()) : wide
    }

    /// rows the chips wrap into at a given width, the way ChipFlow wraps: the
    /// lineage wrap, the row the focus takes of its own, and the kid-band wrap
    @MainActor private static func colRows(_ level: Int,
                                           _ chips: [HipoChip],
                                           _ kids: [HipoChip],
                                           _ span: CGFloat,
                                           _ gap: CGFloat) -> Int {
        let flow = flowWide(level, chips, kids, chipSize)
        var rows = midSplit(level, chips, kids) ? 1 : 0
        if !flow.isEmpty { rows += rowsIn(flow, span, gap) }
        if !kids.isEmpty { rows += rowsIn(kidWide(kids, chipSize), span, gap) }
        return rows
    }

    /// height a row count stacks to, on a given gap, padding and type size
    @MainActor private static func stackHigh(_ rows: Int,
                                             _ gap: CGFloat,
                                             _ padY: CGFloat,
                                             _ size: CGFloat = chipSize) -> CGFloat {
        CGFloat(rows) * rowHigh(padY, size) + CGFloat(rows - 1) * gap
    }

    /// a column overrunning the card by no more than `fitNear`, and by no more
    /// than its rows can give back, squeezes onto the card and stays centered:
    /// the gaps go first, the capsule padding only for what is left. A real
    /// overrun, past either bound, is left to `colPack` to compact
    @MainActor private static func colNear(_ level: Int,
                                           _ chips: [HipoChip],
                                           _ kids: [HipoChip],
                                           _ span: CGFloat,
                                           _ high: CGFloat)
    -> (gap: CGFloat, padY: CGFloat, fits: Bool) {

        let room = high - fitSlack
        let rows = colRows(level, chips, kids, span, rowGap)
        let tall = stackHigh(rows, rowGap, chipPadY)
        let loose = (gap: rowGap, padY: chipPadY, fits: false)
        if tall <= room { return (rowGap, chipPadY, true) }
        guard tall - room <= fitNear else { return loose }
        let gap = rows > 1
        ? max(gapLeast, rowGap - (tall - room) / CGFloat(rows - 1))
        : rowGap
        let over = stackHigh(rows, gap, chipPadY) - room
        let padY = over <= 0 ? chipPadY : chipPadY - over / (2 * CGFloat(rows))
        guard padY >= padLeast else { return loose }
        // the tighter gap only ever packs the rows shorter, so the fit holds
        return (gap, padY, true)
    }

    /// the loosest gap and capsule padding a column stands on at one chip type
    /// size: the gap walks down its ladder first, each rung re-wrapped at the
    /// gap it would draw with, and the padding gives back only the remainder.
    /// nil when even the tightest stack still overruns the room.
    /// `tail` is the rows standing under the flow, the center column's focus;
    /// `kid` is the band wrapping under that, on its own rows
    private static func flowRows(_ wide: [CGFloat],
                                 _ kid: [CGFloat],
                                 _ span: CGFloat,
                                 _ gap: CGFloat,
                                 _ tail: Int) -> Int {
        var rows = tail
        if !wide.isEmpty { rows += rowsIn(wide, span, gap) }
        if !kid.isEmpty { rows += rowsIn(kid, span, gap) }
        return rows
    }

    @MainActor private static func packAt(_ wide: [CGFloat],
                                          _ kid: [CGFloat],
                                          _ span: CGFloat,
                                          _ room: CGFloat,
                                          _ size: CGFloat,
                                          _ tail: Int = 0)
    -> (gap: CGFloat, padY: CGFloat)? {

        var gap = rowGap
        while gap >= gapPack {
            let rows = flowRows(wide, kid, span, gap, tail)
            if stackHigh(rows, gap, chipPadY, size) <= room {
                return (gap, chipPadY)
            }
            gap -= gapStep
        }
        let rows = flowRows(wide, kid, span, gapPack, tail)
        let over = stackHigh(rows, gapPack, chipPadY, size) - room
        let padY = chipPadY - over / (2 * CGFloat(rows))
        return padY >= padPack ? (gapPack, padY) : nil
    }

    /// a pred or succ column past the near fit compacts instead of scrolling:
    /// the gap and padding run to their tighter compaction floors first, and
    /// only then the chip type steps down, a step at a time, until the stack
    /// stands on the card. A narrower chip also wraps into fewer rows, so the
    /// step pays twice. A center column carrying a lineage compacts on the same
    /// ladder; carrying the focus alone it is left at its own size, since one
    /// capsule stands on every card height. A column still overrunning at
    /// `sizeLeast` keeps that floor and scrolls, which is the one case the card
    /// cannot compact away — and the one the center column truncates instead
    @MainActor private static func colPack(_ level: Int,
                                           _ chips: [HipoChip],
                                           _ kids: [HipoChip],
                                           _ span: CGFloat,
                                           _ high: CGFloat)
    -> (gap: CGFloat, padY: CGFloat, size: CGFloat, fits: Bool) {

        let near = colNear(level, chips, kids, span, high)
        if near.fits || (level == 0 && !midSplit(level, chips, kids)) {
            return (near.gap, near.padY, chipSize, near.fits)
        }
        let room = high - fitSlack
        let tail = midSplit(level, chips, kids) ? 1 : 0
        var size = chipSize
        while size >= sizeLeast {
            let wide = flowWide(level, chips, kids, size)
            if let pack = packAt(wide, kidWide(kids, size), span, room, size, tail) {
                return (pack.gap, pack.padY, size, true)
            }
            size -= sizeStep
        }
        return (gapPack, padPack, sizeLeast, false)
    }

    /// the center column head-truncates once the card is out of room even at
    /// the compaction floor: the farthest ancestors go first, one `+n` capsule
    /// standing in for the ones dropped, so the parent and its own parent are
    /// the last lineage to go. The focus alone is the floor
    @MainActor private static func midTrim(_ level: Int,
                                           _ chips: [HipoChip],
                                           _ kids: [HipoChip],
                                           _ span: CGFloat,
                                           _ high: CGFloat) -> [HipoChip] {

        guard midSplit(level, chips, kids), let mid = chips.last else { return chips }
        // a kid band that overruns on its own is not the lineage's debt: keep
        // the lineage whole and let the column scroll
        if !colPack(level, [mid], kids, span, high).fits { return chips }
        var dads = Array(chips.dropLast())
        var cut = 0
        while true {
            let mark = cut > 0 ? [HipoChip(id: dadMark, name: "+\(cut)")] : []
            let show = mark + dads + [mid]
            if colPack(level, show, kids, span, high).fits { return show }
            guard !dads.isEmpty else { return [mid] }
            dads.removeFirst()
            cut += 1
        }
    }

    /// can the card take one more column beside the ones already standing: the
    /// whole run still holds at the widths its chips ask for, nothing scaled
    /// down, and the added column's own stack fits after the near-fit squeeze.
    /// The card asks this before it opens a level on its own.
    /// The gate deliberately weighs `colNear`, the uncompacted arithmetic: a
    /// column the card can only hold by compacting is not reason enough to open
    /// a level nobody asked for, so compaction never widens the auto-fill.
    /// The widths it weighs are the grid's, the same ask `columns` starts from,
    /// so a level opens only when the card holds every cluster at its own grid
    @MainActor static func addFits(_ standing: [HipoLevel],
                                   _ add: HipoLevel,
                                   _ size: CGSize) -> Bool {

        let levels = standing.filter { !$0.chips.isEmpty } + [add]
        let gaps = gapSpan(levels.count) * CGFloat(levels.count - 1)
        let rows = rowCount(size.height)
        let span = levels.map { colNeed($0.id, $0.chips, $0.kids, rows) }
        guard span.reduce(0, +) <= size.width - gaps else { return false }
        return colNear(add.id, add.chips, add.kids,
                       span[levels.count - 1], size.height).fits
    }

    /// narrowest width the two flows wrap into `rows` rows at, counted the way
    /// the column renders them — each flow wraps on its own — bracketed by the
    /// widest capsule and the whole run laid on one line. The greedy wrap never
    /// gains a row from more width, so the bracket bisects cleanly
    private static func spanFor(_ wide: [CGFloat],
                                _ kid: [CGFloat],
                                _ rows: Int,
                                _ gap: CGFloat) -> CGFloat {

        let all = wide + kid
        var low = all.max() ?? colLeast
        var high = all.reduce(0) { $0 + $1 + gap }
        if flowRows(wide, kid, low, gap, 0) <= rows { return low }
        for _ in 0 ..< 14 {
            let mid = (low + high) / 2
            if flowRows(wide, kid, mid, gap, 0) <= rows { high = mid } else { low = mid }
        }
        return high
    }

    /// narrower than the card: the width left over buys rows back. Each pass
    /// hands one level exactly what it needs to drop a row, the levels the card
    /// cannot show whole asking first and the deepest stack ahead of the rest,
    /// so a column flows into two and three chips a row instead of standing
    /// single file while the card has the width for it. A column standing at its
    /// grid takes no more, so spare width never flattens a cluster into one long
    /// strip. Width is spent before `colPack` compacts the height and long
    /// before it scales the type down
    @MainActor private static func grow(_ span: [CGFloat],
                                        _ levels: [HipoLevel],
                                        _ room: CGFloat,
                                        _ rows: Int) -> [CGFloat] {

        var span = span
        let wide = levels.map { flowWide($0.id, $0.chips, $0.kids, chipSize) }
        let kid = levels.map { kidWide($0.kids, chipSize) }
        let tail = levels.map { midSplit($0.id, $0.chips, $0.kids) ? 1 : 0 }
        for _ in 0 ..< 12 {
            let spare = room - span.reduce(0, +)
            guard spare > 0.5 else { break }
            var pickAt = -1
            var pickRank = (0, 0)
            var pickAdd = CGFloat(0)
            for at in span.indices {
                let deep = flowRows(wide[at], kid[at], span[at], rowGap, tail[at])
                let want = gridRows(wide[at].count + kid[at].count, rows - tail[at]) + tail[at]
                guard deep > want else { continue }
                let rank = (deep > rows ? 1 : 0, deep)
                guard rank > pickRank else { continue }
                let need = spanFor(wide[at], kid[at], deep - 1 - tail[at], rowGap) - span[at]
                guard need > 0.5, need <= spare else { continue }
                pickAt = at
                pickRank = rank
                pickAdd = need
            }
            guard pickAt >= 0 else { break }
            span[pickAt] += pickAdd
        }
        return span
    }

    /// wider than the card: the columns still above the floor give back their
    /// share, the ones already at it are held, re-weighed each pass
    private static func shrink(_ span: [CGFloat], _ room: CGFloat) -> [CGFloat] {

        var span = span
        // a card too narrow even for the floor splits evenly below it
        let least = min(colLeast, room / CGFloat(span.count))
        for _ in 0 ..< 8 {
            let total = span.reduce(0, +)
            guard total > room + 0.5 else { break }
            let flex = span.indices.filter { span[$0] > least + 0.5 }
            let held = span.indices.filter { span[$0] <= least + 0.5 }
                .reduce(0) { $0 + span[$1] }
            let free = flex.reduce(0) { $0 + span[$1] }
            guard free > 0 else { break }
            let scale = max(0, room - held) / free
            for at in flex { span[at] = max(least, span[at] * scale) }
        }
        return span
    }

    /// every rendered column, laid out for this card: empty levels never reach
    /// here, each column starts at the width its own near-square grid asks for,
    /// a run wider than the card is scaled down onto the `colLeast` floor, and a
    /// run narrower than it spends what is left packing its deepest stacks wider.
    /// The center column then sits on the card's midline, pushed right
    /// by the least the pred columns need when they outgrow the left half
    @MainActor private func columns(_ size: CGSize) -> HipoRow {

        let levels = leafVm.hipoLevels.filter { !$0.chips.isEmpty }
        guard !levels.isEmpty else { return HipoRow(cols: [], start: 0) }

        let gap = Self.gapSpan(levels.count)
        let gaps = gap * CGFloat(levels.count - 1)
        let room = max(Self.colLeast, size.width - gaps)
        let rows = Self.rowCount(size.height)

        var span = levels.map { Self.colNeed($0.id, $0.chips, $0.kids, rows) }
        if span.reduce(0, +) > room {
            span = Self.shrink(span, room)
        } else {
            span = Self.grow(span, levels, room, rows)
        }

        let run = span.reduce(0, +) + gaps
        var start = CGFloat(0)
        if let mid = levels.firstIndex(where: { $0.id == 0 }) {
            let lead = span[0 ..< mid].reduce(0, +) + gap * CGFloat(mid)
            // the center wants the midline; the pred side may push it right
            start = max(0, size.width / 2 - span[mid] / 2 - lead)
            // the succ side takes what is left of the card before it scrolls
            start = max(0, min(start, size.width - run))
        }
        let cols = levels.indices.map { at -> HipoCol in
            let chips = Self.midTrim(levels[at].id, levels[at].chips,
                                     levels[at].kids, span[at], size.height)
            let fit = Self.colPack(levels[at].id, chips, levels[at].kids,
                                   span[at], size.height)
            return HipoCol(id: levels[at].id,
                           chips: chips,
                           kids: levels[at].kids,
                           span: span[at],
                           gap: fit.gap,
                           padY: fit.padY,
                           size: fit.size,
                           fits: fit.fits)
        }
        return HipoRow(cols: cols, start: start)
    }

    // MARK: - body

    var body: some View {
        GeometryReader { geo in
            if leafVm.hipoCenter < 0 {
                Text("tap a node")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let row = columns(geo.size)
                // a chevron only ever sits between two rendered columns
                HStack(spacing: 0) {
                    ForEach(Array(row.cols.enumerated()), id: \.element.id) { at, col in
                        if at > 0 { chevron(row.cols.count) }
                        slot(col, geo.size.height)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height,
                       alignment: .leading)
                .offset(x: row.start)
            }
        }
        .background(RoundedRectangle(cornerRadius: Menu.cornerRadius)
            .fill(Color.white.opacity(0.06)))
        .padding(.top, Self.cardInset)
        // a rebuilt column has no old scroll position left to honor
        .onChange(of: leafVm.hipoLevels) { scrollAt = [:] }
    }

    private func chevron(_ cols: Int) -> some View {
        Image(systemName: "chevron.compact.right")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.25))
            .frame(width: Self.gapSpan(cols))
    }

    /// the finger has left the column on the side the center sits
    private func past(_ level: Int, _ x: CGFloat, _ colSpan: CGFloat) -> Bool {
        level < 0 ? x > colSpan : x < 0
    }

    /// what the stacked rows overrun the column by; the chip anchors already
    /// carry their own frames, and they resolve past the clip
    private func overSpan(_ spots: [ChipSpot],
                          _ geo: GeometryProxy,
                          _ high: CGFloat,
                          _ shift: CGFloat) -> CGFloat {

        let low = spots.map { geo[$0.bounds].maxY }.max() ?? 0
        return max(0, low + shift - high)
    }

    /// one rendered column. Chips center in the card while they fit, squeezed
    /// when a squeeze is all the fit wants and compacted onto smaller type when
    /// the squeeze runs out; only a column still taller than the card at the
    /// readability floor top-anchors and slides under the finger, since
    /// centering a column taller than the card would clip both of its ends
    private func slot(_ col: HipoCol, _ high: CGFloat) -> some View {

        let shift = scrollAt[col.id] ?? 0

        return stack(col)
        .offset(y: -shift)
        .frame(width: col.span, height: high, alignment: col.fits ? .center : .top)
        .clipped()
        .overlayPreferenceValue(ChipSpotKey.self) { spots in
            // the overlay carries the column's own rendered width, so every hit
            // test and the recenter edge read the frame that was just laid out
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(touchColumn(col.id, spots, geo, geo.size.width,
                                         overSpan(spots, geo, high, shift)))
            }
        }
    }

    /// a column's chips: one wrapping flow, and for a center column carrying a
    /// lineage that flow above the focus capsule, which takes the row under it
    /// however the lineage clusters. The flow is held at the column's own width
    /// so the split stack stands exactly where the whole-column arithmetic put it
    @ViewBuilder
    private func stack(_ col: HipoCol) -> some View {
        if Self.midSplit(col.id, col.chips, col.kids), let mid = col.chips.last {
            VStack(alignment: .leading, spacing: col.gap) {
                if col.chips.count > 1 {
                    ChipFlow(gap: col.gap) {
                        ForEach(Array(col.chips.dropLast())) { chip in
                            chipView(chip, col.id, col.padY, col.size, true)
                        }
                    }
                    .frame(width: col.span, alignment: .leading)
                }
                chipView(mid, col.id, col.padY, col.size, false)
                if !col.kids.isEmpty {
                    ChipFlow(gap: col.gap) {
                        ForEach(col.kids) { chip in
                            chipView(chip, col.id, col.padY, col.size, true)
                        }
                    }
                    .frame(width: col.span, alignment: .leading)
                }
            }
        } else {
            ChipFlow(gap: col.gap) {
                ForEach(col.chips) { chip in
                    chipView(chip, col.id, col.padY, col.size, false)
                }
            }
        }
    }

    private func chipView(_ chip: HipoChip, _ level: Int, _ padY: CGFloat,
                          _ size: CGFloat, _ dad: Bool) -> some View {
        HipoChipView(chip, level, padY, size, dad,
                     leafVm.hipoPicked[level]?.contains(chip.id) ?? false)
    }

    /// one gesture per column, and one hit test inside it: a mostly sideways
    /// drag out the column edge carries the chip to the center, a drag inside
    /// the column slides a tall one or sweeps its rows, a touch alone toggles
    private func touchColumn(_ level: Int,
                             _ spots: [ChipSpot],
                             _ geo: GeometryProxy,
                             _ colSpan: CGFloat,
                             _ most: CGFloat) -> some Gesture {

        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                let dx = drag.translation.width, dy = drag.translation.height
                // wrapped rows sweep sideways too, so only leaving the column
                // toward the center reads as a recenter
                if slide != .recenter, level != 0,
                   abs(dx) >= Self.readSpan,
                   abs(dx) > Self.axisRatio * abs(dy),
                   past(level, drag.location.x, colSpan) {

                    slide = .recenter
                } else if slide == .unread, max(abs(dx), abs(dy)) >= Self.readSpan {
                    if most > 0 || level == 0 {
                        slide = .scroll  // the center column has nothing to sweep
                    } else {
                        slide = .sweep   // the chip touched first fixes the direction
                        if let spot = chipSpotAt(drag.startLocation, spots, geo) {
                            leafVm.sweepHipo(level, spot.id)
                        }
                    }
                }
                switch slide {
                case .sweep:
                    if let spot = chipSpotAt(drag.location, spots, geo) {
                        leafVm.sweepHipo(level, spot.id)
                    }
                case .scroll:
                    let step = dy - slideLast
                    scrollAt[level] = min(most, max(0, (scrollAt[level] ?? 0) - step))
                default: break
                }
                slideLast = dy
            }
            .onEnded { drag in
                switch slide {
                case .recenter:
                    if past(level, drag.location.x, colSpan),
                       let spot = chipSpotAt(drag.startLocation, spots, geo) {
                        leafVm.centerNodeHipo(spot.id)
                    }
                case .scroll: break
                default:
                    if let spot = chipSpotAt(drag.location, spots, geo) {
                        if level == 0 {
                            leafVm.centerNodeHipo(spot.id)
                        } else {
                            leafVm.sweepHipo(level, spot.id)
                        }
                    }
                }
                leafVm.endHipoSweep()
                slide = .unread
                slideLast = 0
            }
    }
}

/// capsule matching the side column chips, tinted by which side it sits on
private struct HipoChipView: View {

    let chip: HipoChip
    let level: Int
    let padY: CGFloat
    let size: CGFloat       /// the compacted type this column measured itself on
    let dad: Bool           /// lineage standing above the focus, not the focus
    let picked: Bool

    init(_ chip: HipoChip, _ level: Int, _ padY: CGFloat,
         _ size: CGFloat, _ dad: Bool, _ picked: Bool) {
        self.chip = chip
        self.level = level
        self.padY = padY
        self.size = size
        self.dad = dad
        self.picked = picked
    }

    /// legend colors: green feeds in, blue is fed out, the center is the focus,
    /// its lineage takes the tree's own red, dimmer still for the mark standing
    /// in for a truncated run, and a picked chip takes the graph's highlight
    private var fill: Color {
        if picked { return .yellow.opacity(0.55) }
        if dad {
            return Color(red: 1.0, green: 0.5, blue: 0.5)
                .opacity(chip.id < 0 ? 0.16 : 0.28)
        }
        switch level {
        case 0    : return .yellow.opacity(0.55)
        case ..<0 : return Color(red: 0.5, green: 1.0, blue: 0.5).opacity(0.28)
        default   : return Color(red: 0.5, green: 0.5, blue: 1.0).opacity(0.28)
        }
    }

    var body: some View {
        Text(chip.name)
            .font(.system(size: size,
                          weight: level == 0 && !dad ? .semibold : .regular))
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundColor(.white)
            // the side padding holds its proportion, so the capsule the column
            // measured is the capsule the row draws
            .padding(.horizontal, LeafGraphHipoView.chipPad(size))
            .padding(.vertical, padY)
            .background(Capsule().fill(fill))
            .contentShape(Capsule())
            .anchorPreference(key: ChipSpotKey.self, value: .bounds) {
                [ChipSpot(chip.name, chip.id, $0)]
            }
    }
}

/// round button flanking the card's fold handle, one hop of the center history
/// each. It takes the handle's own fill, tint and glyph weight, on a circle
/// rather than the handle's rounded rectangle, and a stack with no hop left in
/// it dims its button and stops answering touches
struct HipoRoamView: View {

    let icon: String
    let live: Bool          /// its stack still holds a hop
    let step: () -> Void

    static let span = CGFloat(18)  /// diameter, the whole button
    static let gap = CGFloat(6)    /// clear of the 44pt handle it flanks

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white.opacity(0.75))
            .frame(width: Self.span, height: Self.span)
            .background(Circle().fill(Color.white.opacity(0.22)))
            .contentShape(Circle())
            .opacity(live ? 1 : 0.25)
            .allowsHitTesting(live)
            .onTapGesture { step() }
    }
}
#endif
