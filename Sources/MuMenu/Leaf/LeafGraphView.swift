#if !os(watchOS)
//  created by musesum on 8/5/26

import SwiftUI
import WebKit
import MuFlo

struct LeafGraphView: View {

    @ObservedObject var leafVm: LeafGraphVm
    var size: CGSize { leafVm.panelVm.innerPanel(.none) }
    var webSize: CGSize { leafVm.webSize }

    /// the panel edge, at the value the code panel's own bar carries
    /// (LeafCodeView), so the graph reads as one dark surface to its border
    private static let rimColor = Color.black.opacity(0.9)

    /// the branch owns the shift; the handles write it, the panel reads it
    private var panelOrigin: Binding<CGSize> {
        Binding(get: { leafVm.branchVm.panelOrigin },
                set: { leafVm.branchVm.panelOrigin = $0 })
    }

    var body: some View {
        LeafBezelView(leafVm, .none, Self.rimColor) {
            HStack(spacing: 0) {
                if leafVm.scriptSpan > 0 {
                    LeafGraphScriptView(leafVm)
                        .frame(width: leafVm.scriptSpan,
                               height: leafVm.panelSize.height)
                        .clipped()
                }
                VStack(spacing: 0) {
                    GraphWebView(leafVm)
                        .frame(width: webSize.width, height: webSize.height)
                        .cornerRadius(Menu.cornerRadius)
                        .overlay(alignment: .leading) { GraphScriptFoldView(leafVm) }
                        .overlay(alignment: .trailing) { GraphFoldView(leafVm) }
                        .overlay(alignment: .bottom) { GraphHipoFoldView(leafVm) }
                    if leafVm.hipoSpan > 0 {
                        LeafGraphHipoView(leafVm)
                            .frame(width: webSize.width, height: leafVm.hipoSpan)
                            .clipped()
                    }
                }
                // mounted only while it has a span, the way the script column
                // is: a zero-width column still lays its rows out at their own
                // width and still hit tests there, and the fold handle sits
                // under exactly that spill, which is what swallowed the tap
                // that was meant to open the column again
                if leafVm.sideSpan > 0 {
                    GraphOverView(leafVm)
                        .frame(width: leafVm.sideSpan,
                               height: leafVm.panelSize.height,
                               alignment: .top) // a tall chip field spills downward
                        .clipped()
                }
            }
            .animation(.easeInOut(duration: 0.22), value: leafVm.sideCollapsed)
            .animation(.easeInOut(duration: 0.22), value: leafVm.hipoHidden)
            .animation(.easeInOut(duration: 0.22), value: leafVm.scriptFolded)
            .frame(width: size.width, height: size.height)
            .grabHandle(size    : $leafVm.panelSize,
                        sizeMin : leafVm.sizeMin,
                        sizeMax : leafVm.sizeMax,
                        corners : [.SW, .NW, .SE], // NE is the panel anchor
                        origin  : panelOrigin,
                        anchor  : leafVm.branchVm.treeVm.menuType.corner)
        }
    }
}

/// slim boundary handle shared by the three folds: a touch alone folds the span
/// away, and a drag past `readSpan` resizes it instead. A folded span has no
/// boundary to move, so every touch on it reads as the fold that opens it
private struct GraphSpanView: View {

    let icon: String
    let wide: CGFloat
    let tall: CGFloat
    let sideways: Bool                      /// axis the travel is read on
    let span: () -> CGFloat                 /// the span a drag starts from
    let drag: (CGFloat, CGFloat) -> Void    /// that span, and the travel
    let fold: () -> Void

    private static let readSpan = CGFloat(6) /// travel before the touch resizes

    @State private var begin: CGFloat?

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white.opacity(begin == nil ? 0.75 : 1))
            .frame(width: wide, height: tall)
            .background(RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(begin == nil ? 0.22 : 0.4)))
            .contentShape(Rectangle())
            // .global, not the local space: the handle rides the boundary it is
            // resizing, so a local translation is measured against a frame the
            // drag itself is moving, and the boundary tracks at half the finger
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { touch in
                    let step = touch.translation
                    if begin == nil {
                        let held = span()
                        guard held > 0,
                              max(abs(step.width), abs(step.height)) >= Self.readSpan
                        else { return }
                        begin = held
                    }
                    if let begin {
                        drag(begin, sideways ? step.width : step.height)
                    }
                }
                .onEnded { _ in
                    if begin == nil { fold() }
                    begin = nil
                })
    }
}

/// the bottom card boundary: a drag up gives the card the travel, with the two
/// history hops flanking it while the card stands. Both flanks are one width,
/// so the centered row leaves the handle on the page midline, and the row is
/// bottom aligned, so the handle keeps the same 14pt band. The flanks ride the
/// card because a folded one drops this row onto the panel floor, where a page
/// squeezed to `webLeast` would stand them in the SW and SE grab bands; a card
/// at its own floor holds the row 88pt clear of both
private struct GraphHipoFoldView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        HStack(alignment: .bottom, spacing: HipoRoamView.gap) {
            if !leafVm.hipoHidden {
                HipoRoamView(icon: "chevron.left",
                             live: leafVm.hipoUndoOn,
                             step: { leafVm.undoHipo() })
            }
            GraphSpanView(icon: leafVm.hipoHidden
                          ? "rectangle"
                          : "rectangle.bottomthird.inset.filled",
                          wide: 44, tall: 14, sideways: false,
                          span: { leafVm.hipoSpan },
                          drag: { leafVm.dragHipo($0, $1) },
                          fold: { leafVm.hipoHidden.toggle() })
            if !leafVm.hipoHidden {
                HipoRoamView(icon: "chevron.right",
                             live: leafVm.hipoRedoOn,
                             step: { leafVm.redoHipo() })
            }
        }
        .padding(.bottom, 1)
    }
}

/// the script column boundary; the chevron points the way a tap moves it,
/// mirroring the side column handle, and a drag right widens the column
private struct GraphScriptFoldView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        GraphSpanView(icon: leafVm.scriptFolded ? "chevron.right" : "chevron.left",
                      wide: 14, tall: 44, sideways: true,
                      span: { leafVm.scriptSpan },
                      drag: { leafVm.dragScript($0, $1) },
                      fold: { leafVm.scriptFolded.toggle() })
        .padding(.leading, 1)
    }
}

/// the side column boundary; a drag left widens the column
private struct GraphFoldView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        GraphSpanView(icon: leafVm.sideCollapsed ? "chevron.left" : "chevron.right",
                      wide: 14, tall: 44, sideways: true,
                      span: { leafVm.sideSpan },
                      drag: { leafVm.dragSide($0, $1) },
                      fold: { leafVm.sideCollapsed.toggle() })
        .padding(.trailing, 1)
    }
}

/// side column top: regex over node names, with a live match count
private struct GraphSearchView: View {

    @ObservedObject var leafVm: LeafGraphVm
    @FocusState private var editing: Bool
    @State private var text = ""
    @State private var pending: Task<Void, Never>?
    @State private var resting: Task<Void, Never>?

    static let rowSpan = CGFloat(28)
    private static let runDelay = UInt64(200)    /// keystroke settles into a query
    private static let restDelay = UInt64(1200)  /// query settles into a history entry

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    private func searchSoon(_ delay: UInt64) {
        pending?.cancel()
        let pattern = text
        pending = Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay * 1_000_000)
            }
            if Task.isCancelled { return }
            leafVm.search(pattern)
        }
    }

    /// a pattern is recorded once it has run and been left alone
    private func recordSoon(_ delay: UInt64) {
        resting?.cancel()
        let pattern = text
        resting = Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay * 1_000_000)
            }
            if Task.isCancelled { return }
            leafVm.recordSearch(pattern)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            TextField("search or /regex/", text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .focused($editing)
                .onSubmit {
                    searchSoon(0)
                    recordSoon(0)
                }
                .onChange(of: text) {
                    searchSoon(Self.runDelay)
                    recordSoon(Self.restDelay)
                }
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                Text("\(leafVm.matchCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            Button {
                leafVm.searchListing.toggle()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray.opacity(leafVm.searchHistory.isEmpty ? 0.3 : 1))
                    .frame(width: 14, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(leafVm.searchHistory.isEmpty)
        }
        .padding(.horizontal, 6)
        .frame(height: Self.rowSpan)
        .background(RoundedRectangle(cornerRadius: 6)
            .fill(Color.white.opacity(0.12)))
        .padding(6)
        .onChange(of: editing) {
            NextFrame.shared.pause = $1
            if !$1 { recordSoon(0) }    // leaving the field settles the pattern
        }
        .onChange(of: leafVm.searchRecall) {
            guard let recall = leafVm.searchRecall else { return }
            leafVm.searchRecall = nil
            text = recall               // the field runs it like any other edit
            leafVm.recordSearch(recall) // the pick itself is the newest search
        }
        .onDisappear { NextFrame.shared.pause = false }
    }
}

/// recent searches, most recent first; a pick fills the field and runs it
private struct GraphHistoryView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(leafVm.searchHistory, id: \.self) { item in
                Text(item)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { leafVm.recallSearch(item) }
                if item != leafVm.searchHistory.last {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 6)
            .fill(Color(white: 0.17))
            .shadow(radius: 4))
    }
}

/// side column: search, keyword sections, page controls, legend
private struct GraphOverView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        // the history list floats over the column, above its own dismiss catcher
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                GraphSearchView(leafVm)
                // the sections take the height the controls leave and scroll
                // past it: a node with 32 wires used to push the mode capsule
                // and the sliders off the column floor, where nothing reaches
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        GraphFieldView(leafVm)
                        GraphNotesView(leafVm.commentLines)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                }
                GraphControlsView(leafVm)
                GraphLegendView(leafVm)
            }
            if leafVm.searchListing {
                Color.white.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { leafVm.searchListing = false }
                GraphHistoryView(leafVm)
                    .padding(.horizontal, 6)
                    .offset(y: GraphSearchView.rowSpan + 8)
            }
        }
    }
}

/// link color key doubling as the filter row; a dim swatch is a color switched off
private struct GraphLegendView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    /// one swatch: page color name, link color, label
    private struct GraphLegendKey: Identifiable {
        let id: String
        let color: Color
        let title: String
    }
    private static let keys = [
        GraphLegendKey(id: "red",   color: .init(red: 1.0, green: 0.5, blue: 0.5), title: "name"),
        GraphLegendKey(id: "green", color: .init(red: 0.5, green: 1.0, blue: 0.5), title: "in"),
        GraphLegendKey(id: "blue",  color: .init(red: 0.5, green: 0.5, blue: 1.0), title: "out"),
        GraphLegendKey(id: "yellow", color: .init(red: 1.0, green: 0.78, blue: 0.25), title: "sync")]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Self.keys) { key in
                let on = leafVm.colorOn[key.id] ?? true
                Button {
                    leafVm.toggleColor(key.id)
                } label: {
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(key.color.opacity(on ? 0.75 : 0.15))
                            .frame(width: 9, height: 9)
                        Text(key.title)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundColor(.white.opacity(on ? 0.5 : 0.2))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 10)      // sets the key apart from the Depth slider above
        .padding(.bottom, 6)
    }
}

/// chip name plus its frame, resolved in the chip field's own space;
/// the card carries a node id here, the keyword field has none to carry
struct ChipSpot {
    let name: String
    let id: Int
    let bounds: Anchor<CGRect>

    init(_ name: String, _ id: Int, _ bounds: Anchor<CGRect>) {
        self.name = name
        self.id = id
        self.bounds = bounds
    }

    init(_ name: String, _ bounds: Anchor<CGRect>) {
        self.init(name, -1, bounds)
    }
}

struct ChipSpotKey: PreferenceKey {
    static let defaultValue = [ChipSpot]()
    static func reduce(value: inout [ChipSpot], nextValue: () -> [ChipSpot]) {
        value += nextValue()
    }
}

/// the one hit test behind every chip sweep: touch down, drag over and release
func chipSpotAt(_ point: CGPoint,
                _ spots: [ChipSpot],
                _ geo: GeometryProxy) -> ChipSpot? {
    for spot in spots where geo[spot.bounds].contains(point) {
        return spot
    }
    return nil
}

/// wrapping rows sized to the column width; no scroll view, nothing clipped
struct ChipFlow: Layout {

    let gap: CGFloat

    /// subview rects for a given width, plus the size they add up to
    private func rows(_ subviews: Subviews, _ span: CGFloat) -> ([CGRect], CGSize) {
        var spots = [CGRect]()
        var x = CGFloat(0), y = CGFloat(0), rowHigh = CGFloat(0), wide = CGFloat(0)
        for view in subviews {
            let fit = view.sizeThatFits(ProposedViewSize(width: span, height: nil))
            let w = min(fit.width, span)
            if x > 0, x + w > span {
                x = 0
                y += rowHigh + gap
                rowHigh = 0
            }
            spots.append(CGRect(x: x, y: y, width: w, height: fit.height))
            x += w + gap
            wide = max(wide, x - gap)
            rowHigh = max(rowHigh, fit.height)
        }
        return (spots, CGSize(width: wide, height: y + rowHigh))
    }

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        rows(subviews, proposal.width ?? .infinity).1
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        let spots = rows(subviews, bounds.width).0
        for (index, view) in subviews.enumerated() {
            view.place(at: CGPoint(x: bounds.minX + spots[index].minX,
                                   y: bounds.minY + spots[index].minY),
                       anchor: .topLeading,
                       proposal: ProposedViewSize(spots[index].size))
        }
    }
}

/// keyword sections under one drag: a sweep toggles every chip it crosses
private struct GraphFieldView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GraphChipsView(leafVm, "Inputs", leafVm.inputNames)
            GraphChipsView(leafVm, "Outputs", leafVm.outputNames)
        }
        .overlayPreferenceValue(ChipSpotKey.self) { spots in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(sweep(spots, geo))
            }
        }
    }

    /// touch down, drag over and release all run the same hit test
    private func sweep(_ spots: [ChipSpot], _ geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if let spot = chipSpotAt(drag.location, spots, geo) {
                    leafVm.sweepChip(spot.name)
                }
            }
            .onEnded { drag in
                if let spot = chipSpotAt(drag.location, spots, geo) {
                    leafVm.sweepChip(spot.name)
                }
                leafVm.endChipSweep()
            }
    }
}

/// one titled run of keyword chips, wrapped within the column width
private struct GraphChipsView: View {

    @ObservedObject var leafVm: LeafGraphVm
    let title: String
    let names: [String]

    init(_ leafVm: LeafGraphVm, _ title: String, _ names: [String]) {
        self.leafVm = leafVm
        self.title = title
        self.names = names
    }

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.gray)
        if names.isEmpty {
            GraphNoneView()
        } else {
            ChipFlow(gap: 4) {
                ForEach(names, id: \.self) { name in
                    GraphChipView(leafVm, name)
                }
            }
        }
    }
}

/// dim stand-in that keeps an empty section on screen
private struct GraphNoneView: View {

    var body: some View {
        Text("none")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.3))
    }
}

/// keyword chip; the field's sweep gesture owns every hit test
private struct GraphChipView: View {

    @ObservedObject var leafVm: LeafGraphVm
    let name: String
    var lit: Bool { leafVm.highlights.contains(name) }

    init(_ leafVm: LeafGraphVm, _ name: String) {
        self.leafVm = leafVm
        self.name = name
    }

    var body: some View {
        Text(name)
            .font(.system(size: 11))
            .lineLimit(1)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(lit
                                       ? Color.yellow.opacity(0.55)
                                       : Color.white.opacity(0.15)))
            .anchorPreference(key: ChipSpotKey.self, value: .bounds) {
                [ChipSpot(name, $0)]
            }
    }
}

/// cleaned comment fragments for the focused node
private struct GraphNotesView: View {

    let lines: [String]

    init(_ lines: [String]) { self.lines = lines }

    var body: some View {
        Text("Comments")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.gray)
        if lines.isEmpty {
            GraphNoneView()
        } else {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// page controls parked at the bottom of the side column
private struct GraphControlsView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            GraphModeView(leafVm)
            GraphMenuView(leafVm)
            Text("Community")
            Slider(value: $leafVm.communityLevel, in: 0...1)
            Text("Depth \(leafVm.depthTitle)")
            // the hold marks the drag for the page's friction ramp; no energy
            // rides on it. `onEditingChanged` is the only touch-down a SwiftUI
            // Slider reports
            Slider(value: $leafVm.graphDepth,
                   in: LeafGraphVm.depthLeast ... LeafGraphVm.depthMost,
                   step: 1,
                   onEditingChanged: { leafVm.holdSlider($0) })
        }
        .font(.system(size: 11))
        .foregroundColor(.white)
        .padding(6)
    }
}

/// the three page channels sharing one row: menu-sync lights the navigated
/// branch green and joins the path sources, icons stand in for the labels that
/// have one, and live rings a node the moment its value fires
private struct GraphMenuView: View {

    @ObservedObject var leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    var body: some View {
        HStack(spacing: 4) {
            GraphTogView("Menu", leafVm.menuSyncOn) { leafVm.menuSyncOn.toggle() }
            GraphTogView("Icon", leafVm.iconModeOn) { leafVm.iconModeOn.toggle() }
            GraphTogView("Live", leafVm.pulseLiveOn) { leafVm.pulseLiveOn.toggle() }
        }
    }
}

/// one channel switch, in the mode capsule's own shape
private struct GraphTogView: View {

    let title: String
    let on: Bool
    let act: () -> Void

    private static let rowSpan = CGFloat(22)
    private static let lit = Color(red: 0.72, green: 0.96, blue: 0.72)

    init(_ title: String, _ on: Bool, _ act: @escaping () -> Void) {
        self.title = title
        self.on = on
        self.act = act
    }

    var body: some View {
        Button(action: act) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(on ? Self.lit : Color.white.opacity(0.2))
                    .frame(width: 9, height: 9)
                Text(title)
                    .font(.system(size: 11, weight: on ? .semibold : .regular))
                    .foregroundColor(.white.opacity(on ? 1 : 0.45))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 5)   // three switches share the row; 8 clipped "Menu"
            .frame(maxWidth: .infinity)
            .frame(height: Self.rowSpan)
            .background(Capsule().fill(Color.white.opacity(on ? 0.3 : 0.12)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// one capsule of three segments; the segment under the touch is the choice,
/// read the same way while the finger moves and where it lifts
private struct GraphModeView: View {

    @ObservedObject var leafVm: LeafGraphVm

    private static let modes = GraphLinkMode.allCases
    private static let rowSpan = CGFloat(22)

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    private func pick(_ x: CGFloat, _ span: CGFloat) {
        let index = min(Self.modes.count - 1, max(0, Int(x / max(1, span))))
        let mode = Self.modes[index]
        if leafVm.linkMode != mode { leafVm.linkMode = mode }
    }

    var body: some View {
        GeometryReader { geo in
            let span = geo.size.width / CGFloat(Self.modes.count)
            HStack(spacing: 0) {
                ForEach(Self.modes) { mode in
                    let on = leafVm.linkMode == mode
                    Text(mode.title)
                        .font(.system(size: 11, weight: on ? .semibold : .regular))
                        .foregroundColor(.white.opacity(on ? 1 : 0.45))
                        .lineLimit(1)
                        .frame(width: span, height: Self.rowSpan)
                        .background(Capsule()
                            .fill(Color.white.opacity(on ? 0.3 : 0))
                            .padding(1.5))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { pick($0.location.x, span) }
                .onEnded { pick($0.location.x, span) })
        }
        .frame(height: Self.rowSpan)
        .background(Capsule().fill(Color.white.opacity(0.12)))
    }
}

/// bundled d3 page, fed one json payload per page load
private struct GraphWebView: UIViewRepresentable {

    static let handlerName = "flod3"
    let leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    func makeCoordinator() -> GraphWebCoordinator { GraphWebCoordinator(leafVm) }

    func makeUIView(context: Context) -> WKWebView {

        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: Self.handlerName)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false

        leafVm.runScript = { [weak webView] script in
            webView?.evaluateJavaScript(script, completionHandler: nil)
        }
        // the mounted page owns the canvas tap; a page clears the pick through
        // its own door — it drops focus, posts -1, and clearPick follows. The
        // one binding lives here so the slot always names a page that loaded
        TouchView.canvasTap = { [weak leafVm] in leafVm?.runScript?("backgroundTap()") }
        guard let url = MuMenu.bundle.url(forResource: "flod3-embed", withExtension: "html") else {
            DebugLog { P("🕸️ graph missing flod3-embed.html") }
            return webView
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: GraphWebCoordinator) {
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: Self.handlerName)
        TouchView.canvasTap = nil   // no page, no tap door: the canvas draws plainly
    }
}

/// injects the flo graph after load; routes node taps and search counts
@MainActor
final class GraphWebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

    private let leafVm: LeafGraphVm

    init(_ leafVm: LeafGraphVm) { self.leafVm = leafVm }

    func webView(_ webView: WKWebView, didFinish: WKNavigation!) {
        let script = "loadGraph(" + leafVm.graphJson() + ")"
        Task { @MainActor in
            do { _ = try await webView.evaluateJavaScript(script) }
            catch { DebugLog { P("🕸️ graph inject \(error.localizedDescription)") } }
            leafVm.applyColors()        // a fresh page starts every color on
            leafVm.applyHighlights()    // and with no selection channel set
            leafVm.applyPicks()
            leafVm.resendMarks()        // the fresh page holds no marks; skip the dedupe
            leafVm.applyMenuIds()
            leafVm.applyIcons()         // glyphs land before the mode that shows them
            leafVm.applyIconMode()
            leafVm.applyLinkMode()      // the capsule and the two sliders keep
            leafVm.applyDepth()         // their state across a reload, so the
            leafVm.applyCommunity()     // page is told what they are showing
            leafVm.applyTunes()         // and so do the Debug group's stops
            leafVm.applyPulseLive()     // the Live channel, and the switches it shows
            leafVm.applyLivePrefs()     // the kept per-node accept/ignore archive
            leafVm.recallLayout()       // recalled positions outrank the resends
            leafVm.settleGraph()        // last: drop whatever the resends re-armed
        }
    }

    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {

        guard let body = message.body as? [String: Any] else { return }
        switch body["kind"] as? String {
        case "search" : leafVm.searchResult(body["matches"] as? Int ?? 0,
                                            body["names"] as? [String] ?? [])
        case "node"   : leafVm.focusNode(body["id"] as? Int ?? -1,
                                         body["comment"] as? String ?? "")
        case "nodes"  : leafVm.focusNodes(body["center"] as? Int ?? -1,
                                          body["ids"] as? [Int] ?? [])
        case "txn"    : leafVm.graphTxn()
        case "layout" : leafVm.saveLayout(body)
        case "live"   : leafVm.saveLivePrefs(body["prefs"] as? [String: Bool] ?? [:])
        default       : DebugLog { P("🕸️ graph ?\(body)") }
        }
    }
}
#endif
