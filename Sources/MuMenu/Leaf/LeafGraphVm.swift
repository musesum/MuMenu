#if !os(watchOS)
//  created by musesum on 8/5/26

import SwiftUI
import Combine
import MuFlo
import MuPeers

/// one card capsule: the node it refocuses, and the name it shows
public struct HipoChip: Identifiable, Hashable {
    public let id: Int
    public let name: String
}

/// one card column; `id` is the signed level, 0 for the center
public struct HipoLevel: Identifiable, Hashable {
    public let id: Int
    public let chips: [HipoChip]
    public let kids: [HipoChip]     /// center column only: tree children under the focus

    init(id: Int, chips: [HipoChip], kids: [HipoChip] = []) {
        self.id = id
        self.chips = chips
        self.kids = kids
    }
}

/// one script line: the node's own emission, its depth, and its fold state
public struct ScriptRow: Identifiable, Equatable {
    public let id: Int          /// flo id, the same id the payload carries
    public let text: String     /// single line, the children block excluded
    public let level: Int       /// depth below the script root
    public let hasChildren: Bool
    public let shown: Bool      /// children standing in the list
}

/// what the page does with the nodes off the connecting paths
public enum GraphLinkMode: String, CaseIterable, Identifiable {
    case focus      /// hidden, and dropped from the forces
    case context    /// grayed in place
    case all        /// left alone

    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
}

/// D3 force-directed view of the whole flo graph
public class LeafGraphVm: LeafVm {

    public static let sideWidth = CGFloat(200)   /// native column beside the page
    public static let scriptWidth = CGFloat(200) /// script column left of the page
    public static let webDefault = CGSize(width: 480, height: 480)
    public static let webMin = CGSize(width: 240, height: 240)
    public static let webLeast = CGFloat(120)   /// page floor a handle drag stops at
    public static let spanLeast = CGFloat(44)   /// narrowest a dragged column goes
    public static let hipoMin = CGFloat(88)     /// two chip rows plus the level rule
    public static let hipoMax = CGFloat(180)
    private static let hipoFraction = 0.22
    static let hipoReachMax = 4                 /// level columns the slider tops out at
    static let depthLeast = 0.0                 /// slider floor; 0 asks for no extension
    static let depthMost = 9.0                  /// slider ceiling, the endless horizon
    static let historyMax = 12                  /// searches kept for recall
    static let hipoStepMax = 32                 /// card centers a hop walks back over
    static let graphStep = Int.min              /// a graph action holding an undo slot
    private let sessionStamp = Int(Date().timeIntervalSince1970)  /// corpus file per run
    private static let historyKey = "flod3.searchHistory"
    private static let pulseKey = "flod3.pulseLive"
    private static let prefsKey = "flod3.livePrefs"
    /// wire tag on every graph message, for the tape's own ledger
    static let syncPath = "graph.sync"

    /// panel at rest; a phone folds the script column, so it adds nothing there
    @MainActor public static var sizeDefault: CGSize {
        CGSize(width: webDefault.width + sideWidth
               + (Menu.phonePortrait ? 0 : scriptWidth),
               height: webDefault.height)
    }

    @Published public var panelSize = LeafGraphVm.sizeDefault {
        didSet { applyPanelSize() }
    }

    @Published public var matchCount = 0
    @Published public var searchRecall: String? /// pending history pick, if any
    @Published public var searchListing = false /// history dropdown showing
    @Published public var searchHistory = [String]()
    @Published public var inputNames = [String]()
    @Published public var outputNames = [String]()
    @Published public var commentLines = [String]()
    @Published public var highlights = Set<String>()

    /// the width a handle drag last asked the side column for; a fold leaves it
    /// standing, so unfolding comes back to the dragged width
    @Published public var sideNeed = LeafGraphVm.sideWidth {
        didSet { cardResized() }
    }

    /// the same memory for the script column
    @Published public var scriptNeed = LeafGraphVm.scriptWidth {
        didSet { cardResized() }
    }

    /// the same memory for the bottom card; nil until a drag sets a height,
    /// and the panel fraction stands until then
    @Published public var hipoNeed: CGFloat? {
        didSet { cardResized() }
    }

    /// side column folded away; the page then fills the panel
    @Published public var sideCollapsed = false {
        didSet { cardResized() }
    }

    /// script column folded away; a phone starts folded, everything else open
    @Published public var scriptFolded = Menu.phonePortrait {
        didSet { applyScriptFold() }
    }

    @Published public var scriptRows = [ScriptRow]()

    /// selected script row, -1 when none; the page focus and the card share it
    @Published public var scriptPicked = -1

    /// the multi-selection the column holds beside the single pick: a subtree a
    /// parent row took in, a command touch's own gathering, or a shift range
    @Published public var scriptMarks = Set<Int>()

    /// top field: regex over the row text, the way the Xcode find bar reads
    @Published public var scriptFind = "" {
        didSet { findScript() }
    }

    /// bottom field: path or regex over node names, narrowing the visible rows
    @Published public var scriptSift = "" {
        didSet { buildScript() }
    }

    /// filter bar options. Comments ride in the row text, so dropping them
    /// rebuilds the rows; the wrap is a layout choice the column makes on its
    /// own. None is persisted — a fresh panel comes back with all four off, so
    /// the rows carry no comment tail and a long row keeps to one clipped line.
    /// Comments off also takes them out of the find field's reach: the pattern
    /// runs over the row text, and the tail is no longer in it, and the same
    /// goes for the `'…'` titles it drops with them
    @Published public var scriptNotes = false {
        didSet { buildScript() }
    }
    @Published public var scriptWrap = false

    /// a parent row taking its whole subtree into the mark set. Off by
    /// default: a plain landing then stands for the one row it landed on, and
    /// that row rides the focus channel, so the mark set is left empty. The
    /// flip is answered at once, both directions, so the standing row does not
    /// wait on the next landing to gain or drop its subtree
    @Published public var scriptGroup = false {
        didSet { applyGroup() }
    }

    /// a verified fan drawn as the shorthand MuFlo resolves back to it. Off by
    /// default, so a row lists every target it wires. The swap is row text, so
    /// it rebuilds the rows the way the comment option does
    @Published public var scriptCompact = false {
        didSet { buildScript() }
    }

    /// the standing selection posted with its own direct wires beside it. Off
    /// by default, so the post carries the gathered set and nothing else. On,
    /// the neighbors ride the same `markIds` channel, which is what puts two
    /// or more sources on the page and engages its path machinery: with one
    /// source there is no path to draw, so Focus, Context and All read alike
    /// at Depth infinity, and with the wires added they part again
    @Published public var scriptEdges = false {
        didSet { applyMarks() }
    }

    /// row index -> the character ranges the find pattern hit in that row
    @Published public var scriptSpans = [Int: [Range<Int>]]()
    @Published public var scriptFound = 0   /// find hits over the whole column
    @Published public var scriptAt = -1     /// row index the cycle rests on

    /// bottom card folded away; the page then keeps the full panel height
    @Published public var hipoHidden = false

    @Published public var hipoCenter = -1        /// card center node, -1 when none
    @Published public var hipoLevels = [HipoLevel]()
    @Published public var hipoPicked = [Int: Set<Int>]()  /// level -> chosen ids

    /// the centers behind the standing one and the ones a hop left ahead of it.
    /// Every recenter pushes the center it left onto `hipoBack` and drops the
    /// forward tail; a hop moves one across without recording itself
    @Published public private(set) var hipoBack = [Int]()
    @Published public private(set) var hipoFore = [Int]()

    /// menu-sync channel; while on, the navigated menu path lights up green
    @Published public var menuSyncOn = false {
        didSet { applyMenuIds(); controlChanged() }
    }

    /// icon channel; while on, a node carrying a glyph shows it instead of its name
    @Published public var iconModeOn = false {
        didSet { applyIconMode(); controlChanged() }
    }

    /// live channel; while on, a node whose value fires wears a fading white
    /// ring, and the edges it touches take the same fade. Off silences the
    /// watch on the flo tree, so a closed channel costs one branch per event
    @Published public var pulseLiveOn = LeafGraphVm.keptPulse {
        didSet {
            UserDefaults.standard.set(pulseLiveOn, forKey: Self.pulseKey)
            applyPulseLive()
            controlChanged()
        }
    }

    /// a fresh install starts lit; the request was for the events to show
    private static var keptPulse: Bool {
        UserDefaults.standard.object(forKey: pulseKey) == nil
        ? true
        : UserDefaults.standard.bool(forKey: pulseKey)
    }

    @Published public var linkMode = GraphLinkMode.all {
        didSet { applyLinkMode(); controlChanged() }
    }
    /// zero switches clustering off; anything above picks the dendrogram cut
    @Published public var communityLevel = 0.0 {
        didSet { applyCommunity(); controlChanged() }
    }
    /// slider stop, 0 through `depthMost`; the top stop is the endless horizon
    @Published public var graphDepth = LeafGraphVm.depthMost {
        didSet {
            applyDepth()
            applyReach()
            controlChanged()
        }
    }
    /// link color filters, keyed by the page's own color names
    @Published public var colorOn = ["red": true, "green": true,
                                     "blue": true, "yellow": true]

    /// one javascript call into the page; set by the web coordinator
    public var runScript: ((String) -> Void)?

    /// the column's modifier reading, handed over by the script view the way
    /// `runScript` is handed over by the web coordinator. A folded column
    /// mounts no responder, so a graph tap under it reads no modifier and
    /// takes the plain path
    weak var scriptKeys: ScriptKeys?

    private var d3Graph: FloD3Graph?
    private var d3Names = [Int: String]()
    private var d3Ids = [String: [Int]]()   /// name -> ids; names may repeat
    private var d3Notes = [Int: String]()   /// id -> raw comment
    private var d3In = [Int: Set<Int>]()    /// id -> nodes feeding it
    private var d3Out = [Int: Set<Int>]()   /// id -> nodes it feeds
    private var searchNames = [String]()    /// latest page search matches
    private var focusId = -1                /// tapped node, -1 when none
    private var sectionId = -1              /// node the sidebar sections stand for
    private var chipAdding: Bool?           /// sweep direction, nil between gestures
    private var chipVisited = Set<String>() /// chips already flipped this sweep
    private var hipoAdding: Bool?           /// card sweep direction
    private var hipoVisited = Set<Int>()    /// card chips already flipped
    private var menuPath = [Int]()          /// navigated menu flo ids, root first
    private var menuSink: AnyCancellable?
    private var sizeSink: AnyCancellable?
    private var iconUris: [Int: String]?    /// id -> png data uri, rasterized once
    private var iconsPosted = false         /// the page has the glyph set
    private var hipoPending = false         /// a card rebuild is already queued
    private var hipoRoam = false            /// a hop is driving the recenter
    private var scriptFlos = [Int: Flo]()   /// id -> node, the whole script tree
    private var scriptShut = Set<Int>()     /// folded ids; empty is fully open
    private var scriptMeasured = false      /// the payload match ran once
    private var scriptHits = [Int]()        /// row indices carrying a find hit
    private var scriptStep = -1             /// cursor into `scriptHits`
    private var d3Kids = [Int: [Int]]()     /// id -> child ids, the payload tree
    private var d3Dad = [Int: Int]()        /// id -> parent id
    private var scriptAnchor = -1           /// row a shift range measures from
    private var marksSent: Set<Int>?        /// mark set the page last took; nil forces a resend
    private var scriptTapping = false       /// a row body tap is the one supernet-expand door
    /// panel width the script column was handed; folding returns exactly this
    private var scriptGrant = Menu.phonePortrait ? 0 : LeafGraphVm.scriptWidth
    private var pulse: GraphPulse?          /// event collector, off the actor
    private var pulseWired = false          /// the flo tree carries the watch

    override public func touchLeaf(_: TouchState, _: Visitor) {}
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { menuTree.flo.name }
    override public func syncVal(_: Visitor) {}
    override public var disablesAutoFade: Bool { true }

    override init(_ menuTree: MenuTree,
                  _ branchVm: BranchVm,
                  _ prevVm: NodeVm?,
                  _ runTypes: [LeafRunwayType]) {

        super.init(menuTree, branchVm, prevVm, runTypes)
        // recall only: the list is read back, never replayed
        searchHistory = UserDefaults.standard.stringArray(forKey: Self.historyKey) ?? []
        Peers.shared.addDelegate(self, for: .gestureItem)
        menuSink = MenuLineage.shared.lineage.sink { [weak self] trees in
            self?.menuNavigated(trees)
        }
        // the feed replays its size, so subscribing is the narrow-screen clamp;
        // the hop keeps the published write out of the posting view's commit
        sizeSink = MenuScreen.shared.size.sink { [weak self] _ in
            DispatchQueue.main.async { self?.clampPanel() }
        }
        // the starting panelSize never fires its own didSet, so the panel takes
        // the script column's width on the next turn of the loop
        DispatchQueue.main.async { [weak self] in self?.applyPanelSize() }
    }

    /// container change: a panel sized for the old screen is pulled back inside
    /// it; an unchanged size returns before the @Published didSet can fire
    private func clampPanel() {
        let fit = sizeMax
        let next = CGSize(width:  min(panelSize.width,  fit.width),
                          height: min(panelSize.height, fit.height))
        guard next != panelSize else { return }
        panelSize = next
    }

    /// screen minus a margin on each edge; upright portrait keeps the full width
    public var sizeMax: CGSize {
        #if os(iOS)
        let bounds = UIScreen.main.bounds.size
        #else
        let bounds = CGSize(width: 1280, height: 1024)
        #endif
        let margin = Menu.diameter2 * 2
        let wide = Menu.phonePortrait ? Menu.padding2 : margin
        return CGSize(width:  max(Self.webMin.width,  bounds.width  - wide),
                      height: max(Self.webMin.height, bounds.height - margin))
    }

    /// resize floor, itself capped by the screen so a narrow phone still fits
    public var sizeMin: CGSize {
        let fit = sizeMax
        return CGSize(width:  min(Self.webMin.width + Self.sideWidth + scriptSpan,
                                  fit.width),
                      height: min(Self.webMin.height, fit.height))
    }

    /// script column width, zero once folded. The panel is the only ceiling it
    /// answers to, which is what keeps the two column clamps from circling
    public var scriptSpan: CGFloat {
        scriptFolded ? 0 : min(scriptNeed, max(0, panelSize.width - Self.webLeast))
    }

    /// side column width, zero once folded; the script column is served first,
    /// so a panel too narrow for both takes the difference out of this one
    public var sideSpan: CGFloat {
        sideCollapsed
        ? 0
        : min(sideNeed, max(0, panelSize.width - scriptSpan - Self.webLeast))
    }

    /// widest each column goes before the page would drop under its floor
    public var sideMost: CGFloat {
        max(Self.spanLeast, panelSize.width - scriptSpan - Self.webLeast)
    }

    public var scriptMost: CGFloat {
        max(Self.spanLeast, panelSize.width - sideSpan - Self.webLeast)
    }

    /// tallest the card goes, its own bounds capped by the page floor
    public var hipoMost: CGFloat {
        max(Self.hipoMin, min(Self.hipoMax, panelSize.height - Self.webLeast))
    }

    /// handle drags: the boundary takes the travel and the page gives it back,
    /// so the outer panel never grows from a handle. A folded span has nothing
    /// to resize, and the handle reads that touch as a fold instead
    public func dragSide(_ begin: CGFloat, _ dx: CGFloat) {
        guard !sideCollapsed else { return }
        sideNeed = min(sideMost, max(Self.spanLeast, begin - dx))
    }

    public func dragScript(_ begin: CGFloat, _ dx: CGFloat) {
        guard !scriptFolded else { return }
        scriptNeed = min(scriptMost, max(Self.spanLeast, begin + dx))
    }

    public func dragHipo(_ begin: CGFloat, _ dy: CGFloat) {
        guard !hipoHidden else { return }
        hipoNeed = min(hipoMost, max(Self.hipoMin, begin - dy))
    }

    /// the panel widens by the column it opens, capped by the screen, and gives
    /// back exactly what that unfold got. A panel already at the cap grants
    /// nothing, so the column comes out of the page instead
    private func applyScriptFold() {
        if scriptFolded {
            let back = scriptGrant
            scriptGrant = 0
            guard back > 0 else { return }
            panelSize = CGSize(width: panelSize.width - back,
                               height: panelSize.height)
        } else {
            let grant = max(0, min(scriptNeed, sizeMax.width - panelSize.width))
            scriptGrant = grant
            guard grant > 0 else { return }
            panelSize = CGSize(width: panelSize.width + grant,
                               height: panelSize.height)
        }
    }

    /// the page's own depth argument: -1 asks for the endless horizon, and the
    /// stops below it ask for that many hops, 0 for no extension at all
    private var depthSend: Int {
        graphDepth >= Self.depthMost ? -1 : Int(graphDepth)
    }

    /// the slider stop as a label; the top stop has no number to show
    public var depthTitle: String {
        graphDepth >= Self.depthMost ? "∞" : "\(Int(graphDepth))"
    }

    /// the Depth slider sets the page depth and the card columns per side:
    /// two slider stops per column, from 1 at rest to `hipoReachMax`
    var hipoReach: Int { Self.hipoReach(graphDepth) }

    static func hipoReach(_ depth: Double) -> Int {
        max(1, min(hipoReachMax, (Int(depth) + 1) / 2))
    }

    /// the card's own height, whether or not it is folded away; a drag replaces
    /// the panel fraction it rests at, within the same bounds
    var hipoTall: CGFloat {
        let want = hipoNeed ?? panelSize.height * Self.hipoFraction
        return min(hipoMost, max(Self.hipoMin, want))
    }

    /// bottom card height, zero once folded
    public var hipoSpan: CGFloat {
        hipoHidden ? 0 : hipoTall
    }

    /// the box the columns lay out in: page wide, the card less its top gap.
    /// Folding the card away leaves the box alone, so the levels it opened on
    /// its own are the ones waiting when it comes back
    var hipoCard: CGSize {
        CGSize(width:  webSize.width,
               height: max(0, hipoTall - LeafGraphHipoView.cardInset))
    }

    /// page area: the panel minus the two columns and the bottom card
    public var webSize: CGSize {
        CGSize(width:  max(0, panelSize.width  - sideSpan - scriptSpan),
               height: max(0, panelSize.height - hipoSpan))
    }

    /// deferred until the page asks: walk to the flo root, encode, keep a decode
    public func graphJson() -> String {
        var walk = menuTree.flo
        while let parent = walk.parent { walk = parent }
        let data = walk.makeD3Data()
        // the payload the page solves, kept beside the layouts for harness replay
        if let dir = Self.sessionDir {
            try? data.write(to: dir.appendingPathComponent("graph.json"), options: .atomic)
        }
        let graph = try? JSONDecoder().decode(FloD3Graph.self, from: data)
        d3Graph = graph
        d3Names = [:]
        d3Ids = [:]
        d3Notes = [:]
        d3In = [:]
        d3Out = [:]
        d3Kids = [:]
        d3Dad = [:]
        hipoBack = []   // ids the replaced payload named
        hipoFore = []
        var hubs = Set<Int>()   // a fold can leave several child links on one hub
        for node in graph?.nodes ?? [] {
            d3Names[node.id] = node.name
            d3Ids[node.name, default: []].append(node.id)
            if let note = node.comment { d3Notes[node.id] = note }
            if node.hub == true { hubs.insert(node.id) }
            // the payload names a hub's one surviving parent, or names none
            if let dad = node.d3Dad { d3Dad[node.id] = dad }
        }
        // the name hierarchy the path resolver walks; the same links the card
        // skips, kept here because a path step is a hierarchy step
        for link in graph?.links ?? [] where link.kind == "child" {
            d3Kids[link.source, default: []].append(link.target)
            // a hub took its parent from the payload; the links only last-win
            if !hubs.contains(link.target) { d3Dad[link.target] = link.source }
        }
        // child links are the name hierarchy, not the wiring, so the card
        // skips them; `<>` wires both directions and lands on both sides
        for link in graph?.links ?? [] where link.kind != "child" {
            if link.kind.contains(">") {
                d3Out[link.source, default: []].insert(link.target)
                d3In[link.target, default: []].insert(link.source)
            }
            if link.kind.contains("<") {
                d3In[link.source, default: []].insert(link.target)
                d3Out[link.target, default: []].insert(link.source)
            }
        }
        buildScript()   // the column reads the comments the decode just filled
        wirePulse()     // the payload names the ids an event is allowed to light
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - script column

    /// the column stands on its own: a page that never loaded still gets rows.
    /// The hop keeps the published write out of the posting view's commit
    public func fillScript() {
        guard scriptRows.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, scriptRows.isEmpty else { return }
            _ = graphJson()
        }
    }

    /// a fold takes the whole subtree with it, the way the menu tree collapses;
    /// unfolding gives one level back, its own children still folded
    public func toggleScript(_ id: Int) {
        if scriptShut.remove(id) == nil, let flo = scriptFlos[id] {
            shutScript(flo)
        }
        buildScript()
    }

    private func shutScript(_ flo: Flo) {
        guard !flo.children.isEmpty else { return }
        scriptShut.insert(flo.id)
        for child in flo.children {
            shutScript(child)
        }
    }

    /// the payload lists its own root first, so the column takes that node; the
    /// parent walk is the fallback while no payload has been decoded
    private func scriptRoot() -> Flo? {
        var walk = menuTree.flo
        while let parent = walk.parent { walk = parent }
        guard let head = d3Graph?.nodes.first?.id, walk.id != head else {
            return walk
        }
        return findFlo(walk, head) ?? walk
    }

    private func findFlo(_ flo: Flo, _ id: Int) -> Flo? {
        if flo.id == id { return flo }
        for child in flo.children {
            if let hit = findFlo(child, id) { return hit }
        }
        return nil
    }

    private func indexScript(_ flo: Flo) {
        scriptFlos[flo.id] = flo
        for child in flo.children {
            indexScript(child)
        }
    }

    /// pre-order walk that stops under a folded node: the menu tree's own flat
    /// list rule, with the polarity inverted so an untouched tree is fully open.
    /// A standing filter narrows the children each row offers, and the folds go
    /// on answering inside that narrowing: a folded ancestor takes its kept
    /// descendants down with it, and unfolding gives them back within the filter
    private func addScript(_ flo: Flo,
                           _ level: Int,
                           _ keep: Set<Int>?,
                           _ rows: inout [ScriptRow]) {

        if let keep, !keep.contains(flo.id) { return }
        let kids = keep == nil
        ? flo.children
        : flo.children.filter { keep?.contains($0.id) ?? false }
        let shown = !scriptShut.contains(flo.id)
        var text = flo.scriptOnlyFlo()
        if scriptCompact { text = Self.shortScript(flo, text) }
        if scriptNotes {
            if let note = d3Notes[flo.id] { text += " " + note }
        } else {
            text = Self.dropTicks(text)
        }
        rows.append(ScriptRow(id: flo.id,
                              text: text,
                              level: level,
                              hasChildren: !kids.isEmpty,
                              shown: shown))
        guard shown else { return }
        for child in kids {
            addScript(child, level + 1, keep, &rows)
        }
    }

    // MARK: - row text

    /// comments off drops the `'…'` titles the exprs carry, the way it drops
    /// the `//` tail: both are prose the script does not run. A `"…"` string is
    /// code and is never touched, nor is a tick standing inside one. The seam
    /// the title leaves closes, so `a('tip' 1)` reads `a(1)` and not `a( 1)`
    static func dropTicks(_ text: String) -> String {
        guard text.contains("'") else { return text }
        let marks = Array(text)
        var out = [Character]()
        var at = 0
        var cut = false
        while at < marks.count {
            let mark = marks[at]
            if mark == "\"" {                   // a string run, kept whole
                let to = Self.shutQuote(marks, at)
                out += marks[at ..< to]
                at = to
            } else if mark == "'" {
                // the title goes with the space on either side of it, and the
                // one space its own separator still wants comes back
                at = Self.shutQuote(marks, at)
                while out.last == " " { out.removeLast() }
                while at < marks.count, marks[at] == " " { at += 1 }
                // the slot goes with the title, so its list separator goes too
                if out.last == "(" || out.last == ",",
                   at < marks.count, marks[at] == "," {
                    at += 1
                    while at < marks.count, marks[at] == " " { at += 1 }
                }
                // a title closing the list leaves the comma before it dangling
                if at < marks.count, marks[at] == ")", out.last == "," {
                    out.removeLast()
                }
                if !out.isEmpty, out.last != "(", at < marks.count,
                   marks[at] != ")", marks[at] != "," { out.append(" ") }
                cut = true
            } else {
                out.append(mark)
                at += 1
            }
        }
        var made = String(out)
        if cut, made.hasSuffix("()") { made.removeLast(2) }
        return made
    }

    /// one past the quoted run opening at `from`; a run the text never closes
    /// takes the rest of it
    private static func shutQuote(_ marks: [Character], _ from: Int) -> Int {
        let mark = marks[from]
        var at = from + 1
        while at < marks.count {
            if marks[at] == "\\" { at = min(marks.count, at + 2); continue }
            if marks[at] == mark { return at + 1 }
            at += 1
        }
        return marks.count
    }

    /// targets a synthesized shorthand asks for. The width gate is the caller's
    /// to set, and 2 is the least a fan can be and still be a fan. It stood at
    /// 6, which no live fan ever reached: of the 352 nodes the startup scripts
    /// build, the widest same-name fan is 2 (`pipe.cell.real <- (draw.out,
    /// camera.out)`), so every synthesized candidate died on the count and the
    /// 29 rows that compacted were the provenance-authored ones alone — the
    /// three declarations at `pipe.flo.h:42-44`, exempt from the gate. The
    /// check is what decides now: `makeD3Shorthand` still keeps only a
    /// candidate whose `findPathFlos` set equals the fan the row listed
    static let fanLeast = 2

    /// a same-kind fan swapped for the shorthand MuFlo verifies for it. The
    /// gate is that resolver, never this scan: a fan it will not verify keeps
    /// every target it listed. Width is the resolver's own gate too, so no
    /// count is taken here — the text a wildcard declaration authored stands
    /// at any width, and only a synthesized `anchor˚name` asks for `fanLeast`
    static func shortScript(_ flo: Flo, _ text: String) -> String {
        guard text.contains("(") else { return text }
        let marks = Array(text)
        var out = ""
        var at = 0
        while at < marks.count {
            guard LeafGraphScriptView.edgeMarks.contains(marks[at]) else {
                out.append(marks[at])
                at += 1
                continue
            }
            var to = at
            while to < marks.count,
                  LeafGraphScriptView.edgeMarks.contains(marks[to]) { to += 1 }
            let ops = String(marks[at ..< to])
            var open = to
            while open < marks.count, marks[open] == " " { open += 1 }
            guard open < marks.count,
                  let shut = Self.shutFan(marks, open),
                  let short = flo.makeD3Shorthand(ops, minFan: Self.fanLeast)
            else {
                out += ops
                at = to
                continue
            }
            out += ops + " " + short
            at = shut + 1
        }
        return out
    }

    /// the last mark of the targets an edge run lists. A run listing more than
    /// one wraps them in a group, and the group's own `)` ends it; a run
    /// naming a single target writes it bare, and it ends where its slot does.
    /// Both forms are read, because a one-target fan is exactly what a `˚name`
    /// declaration leaves on each node it matched
    private static func shutFan(_ marks: [Character], _ open: Int) -> Int? {
        if marks[open] == "(" { return shutParen(marks, open) }
        var deep = 0
        var at = open
        while at < marks.count {
            let mark = marks[at]
            if mark == "(" {
                deep += 1
            } else if mark == ")" {
                if deep == 0 { break }
                deep -= 1
            } else if mark == ",", deep == 0 {
                break
            }
            at += 1
        }
        return at > open ? at - 1 : nil
    }

    /// the `)` closing the `(` at `open`, nil when the run never closes
    private static func shutParen(_ marks: [Character], _ open: Int) -> Int? {
        var deep = 0
        var at = open
        while at < marks.count {
            if marks[at] == "(" {
                deep += 1
            } else if marks[at] == ")" {
                deep -= 1
                if deep == 0 { return at }
            }
            at += 1
        }
        return nil
    }

    private func buildScript() {
        guard let root = scriptRoot() else {
            scriptRows = []
            findScript()
            return
        }
        if scriptFlos.isEmpty { indexScript(root) }
        measureScript(root)
        var rows = [ScriptRow]()
        addScript(root, 0, keepScript(), &rows)
        scriptRows = rows
        findScript()    // the row run moved, so the find ranges move with it
    }

    // MARK: - script find and filter

    /// the ids the bottom field leaves standing: every resolved node and the
    /// chain above it, the way the Xcode filter bar keeps a match in context.
    /// nil is no filter at all, which is not the same as an empty set
    private func keepScript() -> Set<Int>? {
        let query = scriptSift.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return nil }
        var keep = Set<Int>()
        for id in matchIds(query) {
            var walk: Int? = id
            while let at = walk, keep.insert(at).inserted {
                walk = d3Dad[at]
            }
        }
        return keep
    }

    /// the top field: a path query lands on the rows it resolves, and every
    /// other pattern is the case-insensitive regex over the row text, each hit
    /// kept as a character range so the column can tint exactly what matched
    private func findScript() {
        let query = scriptFind.trimmingCharacters(in: .whitespaces)
        if Self.splitPath(query) != nil, d3Graph != nil {
            return findRows(matchIds(query))
        }
        let pattern = Self.unslash(query)
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
        guard !pattern.isEmpty,
              // the page's own rule: a pattern that will not compile is literal
              let seek = Self.makeRegex(pattern) ?? Self.makeRegex(escaped)
        else { return clearFound() }

        var spans = [Int: [Range<Int>]]()
        var hits = [Int]()
        var found = 0
        for (at, row) in scriptRows.enumerated() {
            let text = row.text
            let whole = NSRange(text.startIndex ..< text.endIndex, in: text)
            var list = [Range<Int>]()
            seek.enumerateMatches(in: text, options: [], range: whole) { hit, _, _ in
                guard let hit, let range = Range(hit.range, in: text),
                      !range.isEmpty else { return }
                list.append(text.distance(from: text.startIndex, to: range.lowerBound)
                            ..< text.distance(from: text.startIndex, to: range.upperBound))
            }
            guard !list.isEmpty else { continue }
            spans[at] = list
            hits.append(at)
            found += list.count
        }
        scriptSpans = spans
        scriptFound = found
        scriptHits = hits
        scriptStep = hits.isEmpty ? -1 : 0
        scriptAt = hits.first ?? -1
    }

    /// a path query in the find field hits rows, not text: every resolved node
    /// standing in the column counts once, tinted across its own name, which
    /// `scriptOnlyFlo` always emits first. A node the folds or the filter left
    /// out of the column has no row, and so is not a hit
    private func findRows(_ ids: [Int]) {
        let want = Set(ids)
        var spans = [Int: [Range<Int>]]()
        var hits = [Int]()
        for (at, row) in scriptRows.enumerated() where want.contains(row.id) {
            let name = d3Names[row.id] ?? scriptFlos[row.id]?.name ?? ""
            if !name.isEmpty, row.text.hasPrefix(name) {
                spans[at] = [0 ..< name.count]
            }
            hits.append(at)
        }
        scriptSpans = spans
        scriptFound = hits.count
        scriptHits = hits
        scriptStep = hits.isEmpty ? -1 : 0
        scriptAt = hits.first ?? -1
    }

    private func clearFound() {
        scriptSpans = [:]
        scriptFound = 0
        scriptHits = []
        scriptStep = -1
        scriptAt = -1
    }

    /// return key: the next row carrying a hit, wrapping past the last one
    public func nextFound() {
        guard !scriptHits.isEmpty else { return }
        scriptStep = (scriptStep + 1) % scriptHits.count
        scriptAt = scriptHits[scriptStep]
    }

    /// row body tap: the page focuses and pins the node without folding it, the
    /// card recenters on it, and the row lights. Tapping the standing row again
    /// refires, which brings a panned-away node back to the middle
    public func pickScript(_ id: Int) {
        restWalk()          // a touch ends whatever walk was still settling
        markSub(id)         // the set the landing stands for, set before the
        scriptTapping = true
        centerNodeHipo(id)  // fan-out, which posts it once with the wires merged
        scriptTapping = false
    }

    // MARK: - script multi-selection

    /// the one multi-selection event: the set the column paints, and nothing
    /// else. The page is a subscriber of its own, so a key walk can move the
    /// set row by row and still post once, when the run rests
    public func markScript(_ ids: Set<Int>) {
        if scriptMarks != ids { scriptMarks = ids }
    }

    /// what the page is told to mark. Edges off, this is the gathered set
    /// itself, so the post is exactly what it always was. Edges on, the
    /// standing selection and its own direct wires merge in on the way out.
    /// The merge is transient by design: `scriptMarks` never takes the
    /// neighbors, so the row tint, the anchor, and every set operation
    /// `flipScript` and `spanScript` run go on reading the explicit set alone,
    /// and switching the option off leaves nothing of it behind to clear
    private var markPost: Set<Int> {
        guard scriptEdges, focusId >= 0 else { return scriptMarks }
        var ids = scriptMarks
        ids.insert(focusId)
        ids.formUnion(d3In[focusId] ?? [])
        ids.formUnion(d3Out[focusId] ?? [])
        return ids
    }

    /// subscriber — the page. The set is a channel of its own now, sent through
    /// `markIds` rather than the search door it used to share, so a gathered
    /// set and a running search no longer overwrite one another. A set the page
    /// already holds costs nothing, and a column that never gathered one never
    /// posts at all
    public func applyMarks() {
        let post = markPost
        guard marksSent != post else { return }
        marksSent = post
        runScript?("markIds(\(Self.jsInts(post.sorted())))")
    }

    /// a fresh page holds no marks, whatever was last sent — the reload resend
    /// path drops the dedupe so the standing set is painted again
    public func resendMarks() {
        marksSent = nil
        applyMarks()
    }

    /// a node and every row under it, over the payload hierarchy the card and
    /// the reveal already walk
    static func subScript(_ id: Int, _ kids: [Int: [Int]]) -> Set<Int> {
        var ids = Set<Int>()
        var walk = [id]
        while let at = walk.popLast() {
            guard ids.insert(at).inserted else { continue }
            walk += kids[at] ?? []
        }
        return ids
    }

    /// what a plain landing marks, whether a touch or a key put the cursor
    /// there. Group off is the standing case: the landing stands for the one
    /// row it hit, that row rides the focus channel, and the mark set empties.
    /// Group on gives a parent its whole subtree back. Kept apart from the
    /// tree so the gate is provable without one
    static func markSet(_ id: Int,
                        _ group: Bool,
                        _ kids: [Int: [Int]]) -> Set<Int> {
        guard group, !(kids[id] ?? []).isEmpty else { return [] }
        return subScript(id, kids)
    }

    private func markSub(_ id: Int) {
        scriptAnchor = id
        markScript(Self.markSet(id, scriptGroup, d3Kids))
    }

    /// the option flipped: the standing row remakes its set and posts it now.
    /// `markSub` never writes the option back, so the didSet cannot circle
    private func applyGroup() {
        guard scriptPicked >= 0 else { return }
        markSub(scriptPicked)
        applyMarks()
    }

    /// command touch: the touched row alone flips in or out of the set, and the
    /// graph focus stays where it stands
    public func flipScript(_ id: Int) {
        scriptAnchor = id
        var ids = scriptMarks
        if ids.remove(id) == nil { ids.insert(id) }
        markScript(ids)
        applyMarks()
    }

    /// group tap from the page: the members land as the column's own
    /// multi-selection, and the card recenters on the group's parent where one
    /// exists — the same doors a parent row and a sweep already take
    public func focusNodes(_ center: Int, _ ids: [Int]) {
        if let first = ids.first { scriptAnchor = first }
        markScript(Set(ids))
        if center >= 0 { pickNode(center, nil, .page) }   // its applyMarks posts the set
        else { applyMarks() }
    }

    /// shift touch: every standing row from the anchor to the touched one joins
    /// the set. The anchor stays put, so the range can be redrawn from it
    public func spanScript(_ id: Int) {
        guard let to = scriptRows.firstIndex(where: { $0.id == id }) else { return }
        let from = scriptRows.firstIndex { $0.id == scriptAnchor } ?? to
        var ids = scriptMarks
        for at in min(from, to) ... max(from, to) { ids.insert(scriptRows[at].id) }
        markScript(ids)
        applyMarks()
    }

    // MARK: - script keyboard

    private static let keyRest = UInt64(120)  /// quiet a walk rests in
    private static let keyRun = UInt64(500)   /// widest gap still read as a repeat
    private var keySync: Task<Void, Never>?
    private var keyStamp = DispatchTime.now() /// when the last key landed
    private var keyGap = UInt64(0)            /// measured interval between keys
    private var keyWant = -1                  /// row the resting sync will post
    private var keyHeld = false               /// the page told a walk is running

    /// a key moved the selection: the row lights, scrolls and marks at once,
    /// and the graph focus, the card and the mark post all ride one rest. The
    /// rest is measured back from the last key and widened by the cadence the
    /// run is actually keeping, so a repeat slower than the plain window no
    /// longer outruns it and posts a row at a time; a gap too wide to be a
    /// repeat at all starts a fresh act. The page is told a walk is running
    /// for as long as one is, the way it is told a slider is held
    private func keyPick(_ id: Int) {
        guard id >= 0 else { return }
        if scriptPicked != id { scriptPicked = id }
        keyWant = id
        markSub(id)
        let now = DispatchTime.now()
        let gap = now.uptimeNanoseconds - keyStamp.uptimeNanoseconds
        keyGap = gap > Self.keyRun * 1_000_000 ? 0 : gap
        keyStamp = now
        guard keySync == nil else { return }
        holdWalk(true)
        keySync = Task { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: Self.keyRest * 1_000_000)
                if Task.isCancelled { return }
                guard let self else { return }
                let since = DispatchTime.now().uptimeNanoseconds
                - keyStamp.uptimeNanoseconds
                if since >= Self.keyRest * 1_000_000 + keyGap { break }
            }
            guard let self else { return }
            keySync = nil
            holdWalk(false)
            centerNodeHipo(keyWant)
            applyMarks()
        }
    }

    /// a touch takes the column back, so the walk the page was told to expect
    /// ends with it and nothing lands late
    private func restWalk() {
        keySync?.cancel()
        keySync = nil
        holdWalk(false)
    }

    /// the page lowers its friction while the column walks, the way it does
    /// under a slider thumb; a kind it does not know it accepts and ignores
    private func holdWalk(_ on: Bool) {
        guard keyHeld != on else { return }
        keyHeld = on
        runScript?("interactionHold(\(Self.jsText("script")), \(on))")
    }

    /// index of the selected row among the standing ones, -1 when it is not one
    private var scriptRowAt: Int {
        scriptRows.firstIndex { $0.id == scriptPicked } ?? -1
    }

    /// up / down: the previous or next standing row; no selection starts at the
    /// end the key came from
    public func stepScript(_ down: Bool) {
        guard !scriptRows.isEmpty else { return }
        let at = scriptRowAt
        let next = at < 0
        ? (down ? 0 : scriptRows.count - 1)
        : min(scriptRows.count - 1, max(0, at + (down ? 1 : -1)))
        keyPick(scriptRows[next].id)
    }

    /// option up / down: the first or last standing row
    public func endScript(_ down: Bool) {
        guard let row = down ? scriptRows.last : scriptRows.first else { return }
        keyPick(row.id)
    }

    /// left: fold the selected row. A leaf, or a row already folded, walks out
    /// to its parent instead, which is the source-list rule and keeps the key
    /// from dead-ending inside a subtree
    public func foldScript() {
        let id = scriptPicked
        guard id >= 0 else { return }
        if let row = scriptRows.first(where: { $0.id == id }),
           row.hasChildren, row.shown {
            toggleScript(id)
        } else if let dad = d3Dad[id] {
            keyPick(dad)
        }
    }

    /// right: expand the selected row; a row already open steps into its first
    /// child, the same rule read the other way
    public func openScript() {
        let id = scriptPicked
        guard id >= 0,
              let at = scriptRows.firstIndex(where: { $0.id == id })
        else { return }
        let row = scriptRows[at]
        guard row.hasChildren else { return }
        if row.shown {
            if at + 1 < scriptRows.count { keyPick(scriptRows[at + 1].id) }
        } else {
            toggleScript(id)
        }
    }

    /// option left: every row folds but the root, which has nowhere to go
    public func foldAllScript() {
        guard let root = scriptRoot() else { return }
        scriptShut = []
        for child in root.children { shutScript(child) }
        buildScript()
    }

    /// option right: every fold drops
    public func expandAllScript() {
        scriptShut = []
        buildScript()
    }

    // MARK: - path and regex resolver

    /// the one door both fields go through: a path query walks the payload
    /// hierarchy, anything else is the case-insensitive regex over node names
    /// the page already runs
    public func matchIds(_ query: String) -> [Int] {
        if let steps = Self.splitPath(query) { return pathIds(steps) }
        return regexIds(Self.unslash(query))
    }

    /// query -> (separator, segment) steps, the first step carrying no
    /// separator. Path syntax is any of an unescaped top-level `.`, a top-level
    /// `˚`, or a bare `*` standing as a whole segment. nil leaves the text to
    /// the regex: `/…/` forces that outright, a separator inside `(…)` or `[…]`
    /// or behind a `\` belongs to the pattern, and an empty segment (`.*`, `a.`,
    /// `.b`) is a regex dot, not a path step. A `*` inside a segment (`a*b`) is
    /// not a glob and never was: it stays the regex star it reads as
    static func splitPath(_ query: String) -> [(String, String)]? {
        guard !(query.count > 1
                && query.hasPrefix("/")
                && query.hasSuffix("/"))
        else { return nil }

        var steps = [(String, String)]()
        var seg = "", sep = ""
        var deep = 0
        var slash = false
        for mark in query {
            if slash {
                seg.append(mark)
                slash = false
            } else if mark == "\\" {
                seg.append(mark)
                slash = true
            } else if mark == "(" || mark == "[" {
                deep += 1
                seg.append(mark)
            } else if mark == ")" || mark == "]" {
                deep = max(0, deep - 1)
                seg.append(mark)
            } else if deep == 0, mark == "." || mark == "˚" {
                steps.append((sep, seg))
                sep = String(mark)
                seg = ""
            } else {
                seg.append(mark)
            }
        }
        steps.append((sep, seg))
        guard !steps.contains(where: { $0.1.isEmpty }) else { return nil }
        if steps.count > 1 { return steps }
        // one segment is path syntax only when it is the whole-segment wildcard
        return steps[0].1 == "*" ? steps : nil
    }

    /// each step narrows the live set: `.` takes the children a segment names,
    /// `˚` takes every descendant it names. The first step matches anywhere in
    /// the payload, so a leading `*` is any parent one level up
    private func pathIds(_ steps: [(String, String)]) -> [Int] {
        guard let graph = d3Graph else { return [] }
        var live = Set<Int>()
        for node in graph.nodes where Self.fitsSeg(steps[0].1, node.name) {
            live.insert(node.id)
        }
        for step in steps.dropFirst() {
            var next = Set<Int>()
            for id in live {
                if step.0 == "." {
                    for kid in d3Kids[id] ?? []
                    where Self.fitsSeg(step.1, d3Names[kid] ?? "") {
                        next.insert(kid)
                    }
                } else {
                    var stack = d3Kids[id] ?? []
                    while let kid = stack.popLast() {
                        if Self.fitsSeg(step.1, d3Names[kid] ?? "") { next.insert(kid) }
                        stack.append(contentsOf: d3Kids[kid] ?? [])
                    }
                }
            }
            live = next
            if live.isEmpty { break }
        }
        return live.sorted()
    }

    /// the page's own rule, run natively: an invalid pattern matches literally
    private func regexIds(_ pattern: String) -> [Int] {
        guard !pattern.isEmpty else { return [] }
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
        guard let seek = Self.makeRegex(pattern) ?? Self.makeRegex(escaped)
        else { return [] }
        var ids = [Int]()
        for (id, name) in d3Names {
            let whole = NSRange(name.startIndex ..< name.endIndex, in: name)
            if seek.firstMatch(in: name, options: [], range: whole) != nil {
                ids.append(id)
            }
        }
        return ids.sorted()
    }

    /// one segment against one name: `*` alone takes any segment, everything
    /// else is a case-insensitive regex anchored across the whole name
    static func fitsSeg(_ seg: String, _ name: String) -> Bool {
        if seg == "*" { return true }
        guard let seek = makeRegex("^(?:" + seg + ")$") else { return false }
        let whole = NSRange(name.startIndex ..< name.endIndex, in: name)
        return seek.firstMatch(in: name, options: [], range: whole) != nil
    }

    private static var seekCache = [String: NSRegularExpression]()

    /// compiled once per pattern; a pattern that will not compile answers nil
    static func makeRegex(_ pattern: String) -> NSRegularExpression? {
        guard !pattern.isEmpty else { return nil }
        if let seek = seekCache[pattern] { return seek }
        guard let seek = try? NSRegularExpression(pattern: pattern,
                                                 options: [.caseInsensitive])
        else { return nil }
        seekCache[pattern] = seek
        return seek
    }

    /// script tree against the payload: node counts, and how many nodes carry
    /// the name the payload filed under the same id
    private func measureScript(_ root: Flo) {
        guard !scriptMeasured, let graph = d3Graph else { return }
        scriptMeasured = true
        var same = 0
        for (id, flo) in scriptFlos where d3Names[id] == flo.name { same += 1 }
        DebugLog { P("🕸️ script root \(root.name) flos \(self.scriptFlos.count)"
                     + " nodes \(graph.nodes.count) named \(same)") }
    }

    // MARK: - selection

    /// which side raised a selection; only a native pick is told to the page
    public enum GraphPickFrom { case page, native }

    /// the one selection event. Every path raises this and nothing else: a
    /// graph tap, a script row, a card chip, an arrow key. The five subscribers
    /// below are independent and each guards its own state, so a repeat costs
    /// only the subscribers a repeat should still drive
    public func pickNode(_ id: Int,
                         _ comment: String?,
                         _ from: GraphPickFrom) {
        guard id >= 0 else { return clearPick() }
        focusId = id
        pickSections(id, comment)
        pickHipo(id)
        pickScriptRow(id)
        pickPage(id, from)
        applyMarks()    // last: the merge reads the focus this event just set
    }

    /// background tap: the sections fall back to what the search holds and the
    /// card empties unless one match owns it
    private func clearPick() {
        focusId = -1
        sectionId = -1
        scriptPicked = -1
        markScript([])  // the gathered set clears with the focus
        applySearchSections()
        pickHipo(searchCenter())
        applyMarks()    // no focus left to merge, so the wires drop with it
    }

    /// subscriber — sidebar sections: inputs, outputs, comments
    private func pickSections(_ id: Int, _ comment: String?) {
        guard sectionId != id else { return }
        sectionId = id
        inputNames = neighborNames(id, "<")
        outputNames = neighborNames(id, ">")
        // the page carries the comment; a pick without one reads the payload
        let note = comment.flatMap { $0.isEmpty ? nil : $0 } ?? (d3Notes[id] ?? "")
        commentLines = Self.cleanComment(note)
    }

    /// subscriber — the card recenters. A repeat keeps the picks it holds,
    /// which is why the guard sits here and not on the event
    private func pickHipo(_ id: Int) {
        guard hipoCenter != id else { return }
        stepHipo(hipoCenter)    // the one place a center ever moves
        hipoCenter = id
        hipoPicked = [:]        // a new center is a new question
        buildHipo()
        applyPicks()            // the cleared picks reach the page
    }

    /// subscriber — the source row lights and opens out of whatever fold was
    /// hiding it. The repeat is the point: it brings a scrolled-away row back
    private func pickScriptRow(_ id: Int) {
        revealScript(id)
        if scriptPicked != id { scriptPicked = id }
    }

    /// subscriber — the page. Echo guard: a pick the page raised is never sent
    /// back to it, so each path stops after exactly one hop. Only a script row
    /// body tap may expand a selected supernet; hops and key walks never edit
    private func pickPage(_ id: Int, _ from: GraphPickFrom) {
        guard from == .native else { return }
        runScript?("focusNodeId(\(id), \(scriptTapping))")
    }

    /// what a graph node tap means. A `WKScriptMessage` carries no modifier of
    /// its own, so the branch reads the column's own responder — the same
    /// `ScriptKeys` a row touch reads its modifiers from, which is why the two
    /// surfaces can join one set. Kept apart from the router, the way
    /// `LeafGraphScriptView.readTouch` is, so the table reads straight and is
    /// provable without a device
    static func readNode(_ mods: UIKeyModifierFlags) -> ScriptTouch {
        if mods.contains(.command) { return .flip }
        if mods.contains(.shift) { return .span }
        return .pick
    }

    /// node tap from the page; id -1 falls back to the search selection.
    /// Command joins the touched node to the set the column holds and leaves
    /// the focus where it stands, exactly as a command row touch does; shift
    /// takes the range from the anchor. A background tap carries no node, so
    /// it stays the plain clear whatever the keyboard is holding
    public func focusNode(_ id: Int, _ comment: String) {
        switch Self.readNode(scriptKeys?.mods ?? []) {
        case .flip where id >= 0 : flipScript(id)
        case .span where id >= 0 : spanScript(id)
        default                  : pickNode(id, comment, .page)
        }
    }

    /// card recenter; the page focuses and pins without folding the subtree
    public func centerNodeHipo(_ id: Int) {
        guard id >= 0 else { return }
        pickNode(id, nil, .native)
    }

    // MARK: - card history

    /// what a recenter costs the history: the center it leaves waits on the
    /// back stack, and the tail a hop had left ahead is dropped, since the
    /// navigation just taken is the new forward. An emptied card is no center
    /// to come back to, so only the drop applies. A hop takes neither
    private func stepHipo(_ from: Int) {
        guard !hipoRoam else { return }
        if !hipoFore.isEmpty { hipoFore = [] }
        guard from >= 0 else { return }
        hipoBack.append(from)
        if hipoBack.count > Self.hipoStepMax {
            hipoBack.removeFirst(hipoBack.count - Self.hipoStepMax)
        }
    }

    /// a stack with a hop left in it; its button is live while this holds
    public var hipoUndoOn: Bool { !hipoBack.isEmpty }
    public var hipoRedoOn: Bool { !hipoFore.isEmpty }

    /// the page recorded a user action: it takes the next undo slot, and the
    /// forward tail a hop had left is dropped, exactly as a recenter drops it
    public func graphTxn() {
        if !hipoFore.isEmpty { hipoFore = [] }
        hipoBack.append(Self.graphStep)
        if hipoBack.count > Self.hipoStepMax {
            hipoBack.removeFirst(hipoBack.count - Self.hipoStepMax)
        }
    }

    /// one hop back, the standing center left waiting ahead; a graph slot
    /// replays on the page instead of recentering the card
    public func undoHipo() {
        // a center equal to the standing one is stale — discard, never block
        while let t = hipoBack.last, t != Self.graphStep, t == hipoCenter {
            hipoBack.removeLast()
        }
        guard let to = hipoBack.last else { return }
        if to == Self.graphStep {
            hipoBack.removeLast()
            hipoFore.append(Self.graphStep)
            runScript?("graphUndo()")
            return
        }
        hipoBack.removeLast()
        hipoFore = roamHipo(to, hipoFore)
    }

    /// and one forward again, the standing center left waiting behind
    public func redoHipo() {
        while let t = hipoFore.last, t != Self.graphStep, t == hipoCenter {
            hipoFore.removeLast()
        }
        guard let to = hipoFore.last else { return }
        if to == Self.graphStep {
            hipoFore.removeLast()
            hipoBack.append(Self.graphStep)
            runScript?("graphRedo()")
            return
        }
        hipoFore.removeLast()
        hipoBack = roamHipo(to, hipoBack)
    }

    // MARK: - layout sessions

    /// where the manual sessions accumulate — the corpus a layout algorithm
    /// trains on later; one file per app session, plus the rolling recall file
    private static var sessionDir: URL? {
        guard let docs = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let dir = docs.appendingPathComponent("flod3-sessions", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// rest snapshot from the page: layout plus the transaction ledger. The
    /// recall file rolls; the stamped session file is this run's corpus entry
    public func saveLayout(_ body: [String: Any]) {
        guard let dir = Self.sessionDir else { return }
        let txns = body["txns"] as? [[String: Any]] ?? []
        if txns.isEmpty,
           let held = try? Data(contentsOf: dir.appendingPathComponent("layout.json")),
           let dict = try? JSONSerialization.jsonObject(with: held) as? [String: Any],
           let past = dict["txns"] as? [[String: Any]], !past.isEmpty {
            return   // an empty ledger never overwrites a kept one
        }
        let keep: [String: Any] = ["stamp": Date().timeIntervalSince1970,
                                   "algo": body["algo"] as? String ?? "",
                                   "nodes": body["nodes"] ?? [],
                                   "txns": txns]
        guard let data = try? JSONSerialization.data(withJSONObject: keep) else { return }
        do {
            try data.write(to: dir.appendingPathComponent("layout.json"), options: .atomic)
            try data.write(to: dir.appendingPathComponent("session-\(sessionStamp).json"),
                           options: .atomic)
        } catch {
            DebugLog { P("🕸️ layout save \(error.localizedDescription)") }
        }
        // a hand-edited layout travels; a settle the page ran on its own does
        // not, which is what keeps a taken layout from being sent back
        if !txns.isEmpty {
            sendGraphSync(Self.numberRows(body["nodes"] as? [[Any]] ?? []))
        }
    }

    /// the closing leg of the startup resends: every apply above may have
    /// re-armed a trailing reheat, and the tidy open owes the reader a run at
    /// rest — the page drops the timers and freezes where the layout stands
    public func settleGraph() {
        runScript?("settleCold()")
    }

    /// the recall leg: saved positions land right after the payload does, so
    /// the opening solve starts from where the hand last left the graph. The
    /// algo guard drops files saved before the calm era — every earlier file
    /// may carry a whole-field capture of a mid-reheat scramble, and a
    /// recalled scramble re-saves itself at the next cold, forever
    public func recallLayout() {
        guard let dir = Self.sessionDir,
              let data = try? Data(contentsOf: dir.appendingPathComponent("layout.json")),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              dict["algo"] as? String == "calm",
              let list = dict["nodes"] as? [[Any]], !list.isEmpty,
              let json = try? JSONSerialization.data(withJSONObject: list),
              let text = String(data: json, encoding: .utf8)
        else { return }
        runScript?("applyLayout(\(text))")
    }

    // MARK: - peer sync

    /// set while a peer's state is being applied: the setters reach the page
    /// and the solve, and nothing goes back onto the wire
    var graphRemoting = false
    private var syncSoonItem: DispatchWorkItem?
    /// trailing gap a control burst is collected over before it is sent
    static let syncGap = 0.2

    /// one message per burst: a slider stream leaves one, not sixty
    private func syncSoon() {
        syncSoonItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.sendGraphSync() }
        syncSoonItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.syncGap, execute: item)
    }

    /// the controls, plus the layout when the hand has left one to hand over
    func sendGraphSync(_ nodes: [[Double]] = []) {
        let item = GraphSyncItem(depth: graphDepth,
                                 mode: linkMode.rawValue,
                                 community: communityLevel,
                                 menu: menuSyncOn,
                                 icon: iconModeOn,
                                 colors: colorOn,
                                 nodes: nodes,
                                 live: pulseLiveOn)
        guard let data = try? JSONEncoder().encode(item) else { return }
        Task.detached {
            await Peers.shared.sendItem(.gestureItem, path: Self.syncPath) { data }
        }
    }

    /// a peer's state, taken whole. Every control goes in through its own
    /// setter, so the page hears what a hand would say; the solve those setters
    /// ask for is dropped when the message carries a layout, which is the more
    /// particular answer to the same question
    public func applyGraphSync(_ item: GraphSyncItem) {
        graphRemoting = true
        if graphDepth != item.depth { graphDepth = item.depth }
        if let mode = GraphLinkMode(rawValue: item.mode), linkMode != mode {
            linkMode = mode
        }
        if communityLevel != item.community { communityLevel = item.community }
        if menuSyncOn != item.menu { menuSyncOn = item.menu }
        if iconModeOn != item.icon { iconModeOn = item.icon }
        // an older peer sends no live field; its own channel is left standing
        if let live = item.live, pulseLiveOn != live { pulseLiveOn = live }
        for color in item.colors.keys.sorted() {
            let on = item.colors[color] ?? true
            guard colorOn[color] != on else { continue }
            colorOn[color] = on
            applyColor(color, on)
        }
        graphRemoting = false
        guard !item.nodes.isEmpty else { return }
        applyLayoutNodes(item.nodes)
    }

    /// positions from a peer, through the door the recall file takes
    private func applyLayoutNodes(_ list: [[Double]]) {
        guard let json = try? JSONSerialization.data(withJSONObject: list),
              let text = String(data: json, encoding: .utf8) else { return }
        runScript?("applyLayout(\(text))")
    }

    /// the kept layout as the wire carries it, empty when there is none
    func layoutNodes() -> [[Double]] {
        guard let dir = Self.sessionDir,
              let data = try? Data(contentsOf: dir.appendingPathComponent("layout.json")),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              dict["algo"] as? String == "calm",
              let list = dict["nodes"] as? [[Any]] else { return [] }
        return Self.numberRows(list)
    }

    /// the page's own [id, x, y] rows, narrowed to what Codable carries
    static func numberRows(_ list: [[Any]]) -> [[Double]] {
        list.map { row in row.compactMap { ($0 as? NSNumber)?.doubleValue } }
    }

    /// the hop itself: the taken center recenters through the same door a chip
    /// tap takes, so every subscriber moves with it, and `hipoRoam` keeps that
    /// recenter from recording itself. The far stack comes back carrying the
    /// center that was standing
    private func roamHipo(_ to: Int, _ park: [Int]) -> [Int] {
        restWalk()          // a hop ends whatever walk was still settling
        let from = hipoCenter
        hipoRoam = true
        centerNodeHipo(to)
        hipoRoam = false
        // MuFlo gives [Int] an element-wise `+`, so park + [from] sums; append instead
        guard from >= 0 else { return park }
        var kept = park
        kept.append(from)
        return kept
    }

    /// the node the page just named, brought into the column: every fold above
    /// its row opens, the row's own fold left as it stands. A filter that
    /// excludes the node has no row to open, and the column stays as it is
    private func revealScript(_ id: Int) {
        var opened = false
        var walk = d3Dad[id]
        while let at = walk {
            if scriptShut.remove(at) != nil { opened = true }
            walk = d3Dad[at]
        }
        if opened { buildScript() }
    }

    /// search reply from the page; a tapped node keeps the sections it owns
    public func searchResult(_ count: Int, _ names: [String]) {
        matchCount = count
        searchNames = names
        if focusId < 0 {
            applySearchSections()
            pickHipo(searchCenter())
        }
    }

    /// legend tap; the page drops the color from display, adjacency and forces
    public func toggleColor(_ color: String) {
        let on = !(colorOn[color] ?? true)
        colorOn[color] = on
        applyColor(color, on)
        controlChanged()
    }

    /// page load starts every color on, so only the off ones need resending
    public func applyColors() {
        for color in colorOn.keys.sorted() where colorOn[color] == false {
            applyColor(color, false)
        }
    }

    /// side column search, on commit and debounced on change. The query goes
    /// through `matchIds`, the same door the filter field takes, so the two
    /// fields can never route a pattern differently. The trim is that door's
    /// own rule and applies to the gate and to path resolution; a regex keeps
    /// the text it was typed with, trailing space included
    public func search(_ text: String) {
        let query = text.trimmingCharacters(in: .whitespaces)
        if Self.splitPath(query) != nil, d3Graph != nil {
            let names = Set(matchIds(query).compactMap { d3Names[$0] })
            runScript?("searchNames(\(Self.jsList(names.sorted())))")
        } else {
            runScript?("searchRegex(\(Self.jsText(Self.unslash(text))))")
        }
    }

    /// a pattern that ran and was left alone joins the history: move to front,
    /// capped, and a keystroke the head is a prefix of folds into it
    public func recordSearch(_ text: String) {
        let pattern = text.trimmingCharacters(in: .whitespaces)
        guard !pattern.isEmpty else { return }
        var list = searchHistory
        if let head = list.first, head != pattern, pattern.hasPrefix(head) {
            list.removeFirst()
        }
        list.removeAll { $0 == pattern }
        list.insert(pattern, at: 0)
        if list.count > Self.historyMax {
            list.removeLast(list.count - Self.historyMax)
        }
        searchHistory = list
        UserDefaults.standard.set(list, forKey: Self.historyKey)
    }

    /// history pick; the field takes the text and runs it down its one path
    public func recallSearch(_ text: String) {
        searchListing = false
        searchRecall = text
    }

    /// chip crossed by the field sweep; the first one fixes the direction,
    /// and each name flips at most once until the gesture ends
    public func sweepChip(_ name: String) {
        let adding = chipAdding ?? !highlights.contains(name)
        chipAdding = adding
        guard chipVisited.insert(name).inserted else { return }
        if adding {
            highlights.insert(name)
        } else {
            highlights.remove(name)
        }
        applyHighlights()
    }

    /// gesture end drops the direction and the visited names
    public func endChipSweep() {
        chipAdding = nil
        chipVisited.removeAll()
    }

    /// card chip crossed by a column sweep; a lone touch runs the same path.
    /// The pick opens the column beyond it and lights the node in the graph
    public func sweepHipo(_ level: Int, _ id: Int) {
        guard level != 0 else { return }
        var picked = hipoPicked[level] ?? []
        let adding = hipoAdding ?? !picked.contains(id)
        hipoAdding = adding
        guard hipoVisited.insert(id).inserted else { return }
        if adding {
            picked.insert(id)
        } else {
            picked.remove(id)
        }
        hipoPicked[level] = picked
        buildHipo()
        applyPicks()
    }

    /// gesture end drops the direction and the visited ids
    public func endHipoSweep() {
        hipoAdding = nil
        hipoVisited.removeAll()
    }

    /// a slider stop moved the reach; a pick past it has no column left to sit in
    private func applyReach() {
        guard hipoCenter >= 0 else { return }
        let reach = hipoReach
        let stale = hipoPicked.keys.filter { abs($0) > reach }
        for level in stale { hipoPicked[level] = nil }
        buildHipo()
        if !stale.isEmpty { applyPicks() }
    }

    /// the center's own lineage, farthest ancestor first, the payload head left
    /// out. The card reads it from `d3Dad`, the child-link map `revealScript`
    /// already walks: every card id is a payload id, and a `Flo.parent` walk
    /// would be a second currency to keep in step with it
    private func hipoDads(_ id: Int) -> [HipoChip] {
        var chips = [HipoChip]()
        var walk = d3Dad[id]
        while let at = walk {
            guard let up = d3Dad[at] else { break }  // the root is not lineage
            if let name = d3Names[at] {
                chips.append(HipoChip(id: at, name: name))
            }
            walk = up
        }
        return chips.reversed()
    }

    /// level 1 is the center's own wires; each level beyond is the union the
    /// whole column before it opens while the card holds that union, and the
    /// union its picks open once it does not.
    /// The pred side runs first and the succ side breaks its loops on it.
    /// The center column carries its lineage above the focus and the tree
    /// children under it, so the columns beside it budget for the whole stack;
    /// the kid band is the one place the children stand
    private func buildHipo() {
        guard hipoCenter >= 0, let name = d3Names[hipoCenter] else {
            hipoLevels = []
            return
        }
        let mid = HipoLevel(id: 0, chips: hipoDads(hipoCenter)
                            + [HipoChip(id: hipoCenter, name: name)],
                            kids: hipoChips(Set(d3Kids[hipoCenter] ?? [])
                                .subtracting([hipoCenter])))
        // the succ side always draws its own first column, so the pred pass
        // budgets for it; the succ pass then weighs the whole pred side
        let succ1 = HipoLevel(id: 1, chips: hipoChips(d3Out[hipoCenter] ?? []))
        var seen: Set<Int> = [hipoCenter]
        let pred = hipoSide(d3In, -1, &seen, [mid, succ1])
        let succ = hipoSide(d3Out, 1, &seen, [mid] + pred)
        hipoLevels = pred.reversed() + [mid] + succ
    }

    /// `seen` is the Visitor: the center, then every node the columns take.
    /// Level 1 keeps the center's own wires, so a `<>` pair still lands on
    /// both sides; every level past it drops what a column already holds.
    /// `standing` is what the card already carries, the auto-fill weighs against
    private func hipoSide(_ wires: [Int: Set<Int>],
                          _ sign: Int,
                          _ seen: inout Set<Int>,
                          _ standing: [HipoLevel]) -> [HipoLevel] {
        var levels = [HipoLevel]()
        var front: Set<Int> = [hipoCenter]
        for step in 1 ... hipoReach {
            var ids = Set<Int>()
            for id in front { ids.formUnion(wires[id] ?? []) }
            if step > 1 { ids.subtract(seen) }
            if ids.isEmpty { break }
            seen.formUnion(ids)
            levels.append(HipoLevel(id: sign * step, chips: hipoChips(ids)))
            guard step < hipoReach else { break }
            front = autoFront(wires, sign, step, ids, seen, standing + levels)
            ?? (hipoPicked[sign * step] ?? []).intersection(ids)
            if front.isEmpty { break }
        }
        return levels
    }

    /// the whole column opens the next one when the card can hold that union:
    /// the same blanket adjacency a pick opens, weighed at the width and height
    /// the card would lay it out at. A union the card cannot hold returns nil,
    /// leaving the level to its picks. Auto-filled chips are not picks: they
    /// draw plain and never reach the page.
    /// `addFits` weighs the union at its natural type, never at the compaction
    /// a rendered column may fall back on: the card compacts what it was asked
    /// to show, and never opens a level it can only hold compacted
    private func autoFront(_ wires: [Int: Set<Int>],
                           _ sign: Int,
                           _ step: Int,
                           _ ids: Set<Int>,
                           _ seen: Set<Int>,
                           _ standing: [HipoLevel]) -> Set<Int>? {

        var next = Set<Int>()
        for id in ids { next.formUnion(wires[id] ?? []) }
        next.subtract(seen)   // the Visitor breaks the auto-fill loops too
        guard !next.isEmpty else { return nil }
        let add = HipoLevel(id: sign * (step + 1), chips: hipoChips(next))
        guard LeafGraphHipoView.addFits(standing, add, hipoCard) else { return nil }
        return ids
    }

    /// a resized card takes a different auto-fill, so the columns rebuild off
    /// the commit that resized it; the flag folds a drag's stream into one pass
    private func cardResized() {
        guard hipoCenter >= 0, !hipoPending else { return }
        hipoPending = true
        DispatchQueue.main.async { [weak self] in
            self?.hipoPending = false
            self?.buildHipo()
        }
    }

    /// named ids as chips, in name order; a repeated name orders by id
    private func hipoChips(_ ids: Set<Int>) -> [HipoChip] {
        var chips = [HipoChip]()
        for id in ids.sorted() {
            guard let name = d3Names[id] else { continue }
            chips.append(HipoChip(id: id, name: name))
        }
        chips.sort { (a: HipoChip, b: HipoChip) -> Bool in
            a.name == b.name ? a.id < b.id : a.name < b.name
        }
        return chips
    }

    /// keyword chips; the page paints these in the interconnect style
    public func applyHighlights() {
        runScript?("highlightNames(\(Self.jsList(highlights.sorted())))")
    }

    /// menu navigation; the path is kept whether or not the channel is on, so
    /// switching it on lights the branch already reached
    private func menuNavigated(_ trees: [MenuTree]) {
        menuPath = trees.map { $0.flo.id }
        if menuSyncOn { applyMenuIds() }
    }

    /// menu-sync channel, keyed by flo id; off sends the empty set, which clears
    public func applyMenuIds() {
        runScript?("menuIds(\(Self.jsInts(menuSyncOn ? menuPath : [])))")
    }

    // MARK: - live pulse

    /// One watch over the whole flo tree, added once and never taken back —
    /// `addClosure` only appends. Every value change funnels through
    /// `Flo.activate`, whoever asked for it: a MIDI message off the CoreMIDI
    /// thread, a leaf control under a finger, or either one replayed on this
    /// device from a peer. The closure is shared by every node, so the tree
    /// carries one closure, not one per node, and it touches nothing on the
    /// actor — the collector holds the gate and books the hop.
    private func wirePulse() {
        guard !pulseWired else { return applyPulseLive() }
        pulseWired = true
        let collect = GraphPulse { [weak self] ids in self?.pulsePost(ids) }
        pulse = collect
        let watch: FloVisitor = { [weak collect] flo, _ in collect?.add(flo.id) }
        var walk = menuTree.flo
        while let parent = walk.parent { walk = parent }
        addPulseWatch(walk, watch)
        applyPulseLive()
    }

    private func addPulseWatch(_ flo: Flo, _ watch: @escaping FloVisitor) {
        flo.addClosure(watch)
        for child in flo.children {
            addPulseWatch(child, watch)
        }
    }

    /// `parent.name` where the payload names a parent, the bare name otherwise
    private func pulseName(_ id: Int) -> String {
        let name = d3Names[id] ?? "\(id)"
        guard let dad = d3Dad[id], let above = d3Names[dad] else { return name }
        return above + "." + name
    }

    /// the gate: the channel switch, and a page to post to. The page hears the
    /// switch too, since a channel that is down has no highlight to accept
    public func applyPulseLive() {
        pulse?.live = pulseLiveOn && runScript != nil
        runScript?("setLive(\(pulseLiveOn))")
    }

    /// per-node live preferences, keyed by the node's own dotted path — a flo
    /// id is a process counter that starts over, and the folds a Community cut
    /// invents are forgotten the moment the cut moves
    public func applyLivePrefs() {
        let kept = UserDefaults.standard.dictionary(forKey: Self.prefsKey) as? [String: Bool] ?? [:]
        guard let data = try? JSONSerialization.data(withJSONObject: kept),
              let text = String(data: data, encoding: .utf8) else { return }
        runScript?("livePrefs(\(text))")
    }

    /// the page's own archive call, one whole map per change
    public func saveLivePrefs(_ prefs: [String: Bool]) {
        UserDefaults.standard.set(prefs, forKey: Self.prefsKey)
        DebugLog { P("🕸️ graph live prefs \(prefs.count)") }
    }

    /// one window's worth of fired ids, narrowed to the ones the payload names
    private func pulsePost(_ ids: [Int]) {
        guard pulseLiveOn else { return }
        let known = ids.filter { d3Names[$0] != nil }
        guard !known.isEmpty else { return }
        // the names, not just the count: a node firing every frame is what
        // keeps its edges lit, and the count alone never said which one. The
        // parent rides along because a tree carries many nodes named `in`.
        // Fifteen windows a second buries every other line, so the ledger
        // speaks once per `logGap`
        TimeLog("graph.pulse", interval: Self.logGap) {
            let named = known.map { self.pulseName($0) }.sorted().prefix(9)
            P("🕸️ graph pulse \(known.count) \(named.joined(separator: " "))")
        }
        runScript?("pulseIds(\(Self.jsInts(known)))")
    }

    /// glyph set for the page, keyed by flo id; rasterized once, sent per load
    public func applyIcons() {
        let uris = iconUris ?? makeIconUris()
        iconUris = uris
        iconsPosted = true
        var parts = [String]()
        for id in uris.keys.sorted() {
            parts.append("\"\(id)\":" + Self.jsText(uris[id] ?? ""))
        }
        DebugLog { P("🕸️ graph icons \(uris.count)") }
        runScript?("nodeIcons({" + parts.joined(separator: ",") + "})")
    }

    /// icon channel; a toggle before the page was fed sends the glyphs first
    public func applyIconMode() {
        if !iconsPosted { applyIcons() }
        runScript?("setIconMode(\(iconModeOn))")
    }

    /// whole flo tree, the same walk the payload takes, keeping what has a glyph
    private func makeIconUris() -> [Int: String] {
        var walk = menuTree.flo
        while let parent = walk.parent { walk = parent }
        var uris = [Int: String]()
        addIconUri(walk, &uris)
        return uris
    }

    private func addIconUri(_ flo: Flo, _ uris: inout [Int: String]) {
        if let uri = Self.iconUri(menuTree.makeFloIcon(flo)) {
            uris[flo.id] = uri
        }
        for child in flo.children {
            addIconUri(child, &uris)
        }
    }

    /// sym / img / svg only; text and cursor have no glyph the graph can show
    static func iconUri(_ icon: Icon) -> String? {
        let name = icon.nameOn
        guard !name.isEmpty else { return nil }
        switch icon.typeOn {
        case .symbol:
            let fit = UIImage.SymbolConfiguration(pointSize: iconPoint)
            return blackUri(UIImage(systemName: name, withConfiguration: fit))
        case .image, .svg:
            return blackUri(UIImage.named(name))
        default:
            return nil
        }
    }

    private static let iconPoint = CGFloat(17)  /// glyph box, rasterized at 2x

    /// square box, aspect fitted, alpha filled black: the page inverts for contrast
    private static func blackUri(_ image: UIImage?) -> String? {
        guard let image else { return nil }
        let long = max(image.size.width, image.size.height)
        guard long > 0 else { return nil }
        let fit = CGSize(width:  image.size.width  / long * iconPoint,
                         height: image.size.height / long * iconPoint)
        let spot = CGRect(x: (iconPoint - fit.width) / 2,
                          y: (iconPoint - fit.height) / 2,
                          width: fit.width, height: fit.height)
        let span = CGSize(width: iconPoint, height: iconPoint)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 2
        format.opaque = false
        let png = UIGraphicsImageRenderer(size: span, format: format).pngData { render in
            image.draw(in: spot)
            UIColor.black.setFill()
            render.cgContext.setBlendMode(.sourceIn)
            render.cgContext.fill(CGRect(origin: .zero, size: span))
        }
        return "data:image/png;base64," + png.base64EncodedString()
    }

    /// card picks, their own channel; the page paints these in the search style
    public func applyPicks() {
        var names = Set<String>()
        for ids in hipoPicked.values {
            for id in ids {
                if let name = d3Names[id] { names.insert(name) }
            }
        }
        runScript?("pickNames(\(Self.jsList(names.sorted())))")
    }

    /// a lone search match centers the card; an ambiguous set does not
    private func searchCenter() -> Int {
        let ids = matchedIds()
        return ids.count == 1 ? ids[0] : -1
    }

    /// neighbors over non-tree links carrying `mark`; `<>` counts both ways
    private func neighborNames(_ id: Int, _ mark: Character) -> [String] {
        guard let d3Graph else { return [] }
        var names = [String]()
        var seen = Set<String>()
        for link in d3Graph.links
        where link.kind != "child" && link.kind.contains(mark) {

            let other = (link.source == id ? link.target
                         : link.target == id ? link.source : nil)
            guard let other,
                  let name = d3Names[other],
                  seen.insert(name).inserted else { continue }
            names.append(name)
        }
        return names
    }

    /// no tapped node: the sections span every search match
    private func applySearchSections() {
        guard !searchNames.isEmpty else {
            inputNames = []
            outputNames = []
            commentLines = []
            return
        }
        let ids = matchedIds()
        let skip = Set(searchNames)
        inputNames = unionNames(ids, "<", skip)
        outputNames = unionNames(ids, ">", skip)
        commentLines = matchedNotes(ids)
    }

    /// matched names back to node ids, in name order; a repeated name adds once
    private func matchedIds() -> [Int] {
        var ids = [Int]()
        var seen = Set<Int>()
        for name in Set(searchNames).sorted() {
            for id in d3Ids[name] ?? [] where seen.insert(id).inserted {
                ids.append(id)
            }
        }
        return ids
    }

    /// deduped, sorted neighbors over the whole matched set, minus the set itself
    private func unionNames(_ ids: [Int],
                            _ mark: Character,
                            _ skip: Set<String>) -> [String] {
        var names = Set<String>()
        for id in ids {
            names.formUnion(neighborNames(id, mark))
        }
        return names.subtracting(skip).sorted()
    }

    /// one `name: line` per comment fragment; repeats collide as ForEach ids
    private func matchedNotes(_ ids: [Int]) -> [String] {
        var lines = [String]()
        var seen = Set<String>()
        for id in ids {
            guard let name = d3Names[id], let note = d3Notes[id] else { continue }
            for text in Self.cleanComment(note) {
                let line = name + ": " + text
                if seen.insert(line).inserted { lines.append(line) }
            }
        }
        return lines
    }

    private func applyColor(_ color: String, _ on: Bool) {
        runScript?("setColorOn(\(Self.jsText(color)), \(on))")
    }

    /// the three page channels a fresh page has no memory of. A reload resets
    /// the page to its own defaults while the capsule and the two sliders go on
    /// showing what was picked, so every one of them is resent on load; the
    /// capsule only sends on change, and a mode already held has no change left
    func applyLinkMode() {
        runScript?("setLinkMode(\(Self.jsText(linkMode.rawValue)))")
    }

    func applyDepth() {
        runScript?("setDepth(\(depthSend))")
    }

    func applyCommunity() {
        runScript?("setCommunity(\(communityLevel > 0), \(communityLevel))")
    }

    /// slider touch down and release; the hold marks the drag for the page's
    /// friction ramp — no energy rides on it and no node moves for it
    public func holdSlider(_ on: Bool) {
        runScript?("interactionHold(\(Self.jsText("slider")), \(on))")
    }

    // MARK: - force tuning

    /// the page's force constants, fixed now that the Debug group is gone.
    /// `friction` and `decay` are the page's own alias spellings for
    /// velocityDecay and alphaDecay
    static let frictDefault = 0.55               // velocityDecay
    /// alphaDecay, Dev's stop: the field cools in about a dozen ticks where
    /// the page's own 0.045 takes a hundred and fifty
    static let decayDefault = 0.3
    static let polarDefault = 0.05               // polarWeight
    static let chargeDefault = -50.0             // charge

    /// spring maximum, one per legend color. MEASURED on the 573/607 fixture
    /// at flod3-v3d5: red is clean to 1.15, fires the tick guard 21 times at
    /// 1.20 and 207 at 1.25, and past that runs away, so red stands under the
    /// guard's first shot. Green, blue and yellow ride edgeStrength 0.80
    /// against red's childStrength 2.4 and are clean through 4
    static let springRedMax = 1.1
    static let springMax = 4.0
    /// rest-length multiplier at the measured floor: the shortest clean link
    static let lengthMin = 0.25

    /// the whole set, sent on every page load — a reload puts the page back
    /// onto its own TUNE literals, which are not these
    public func applyTunes() {
        applyTune("friction", Self.frictDefault)
        applyTune("decay", Self.decayDefault)
        applyTune("polarWeight", Self.polarDefault)
        applyTune("charge", Self.chargeDefault)
        applyTune("springRed", Self.springRedMax)
        applyTune("springGreen", Self.springMax)
        applyTune("springBlue", Self.springMax)
        applyTune("springYellow", Self.springMax)
        applyTune("lengthRed", Self.lengthMin)
        applyTune("lengthGreen", Self.lengthMin)
        applyTune("lengthBlue", Self.lengthMin)
        applyTune("lengthYellow", Self.lengthMin)
    }

    private func applyTune(_ key: String, _ value: Double) {
        runScript?("setTune(\(Self.jsText(key)), \(value))")
    }

    static let logGap = 4.0      /// seconds between repeats of one log line

    /// one control moved: each setter already told the page, so the peers owe
    /// the new state and nothing more — no solve rides behind a control. A
    /// control put here by a peer owes nothing: the state came from the wire
    private func controlChanged() {
        if !graphRemoting { syncSoon() }
    }

    /// panel geometry follows the grab handle, in Menu.diameter units
    private func applyPanelSize() {
        let unit = CGSize(width:  panelSize.width  / Menu.diameter,
                          height: panelSize.height / Menu.diameter)
        panelVm.aspectSz = unit
        branchVm.panelVm.aspectSz = unit
        cardResized()
        refreshView()
    }

    /// display cleanup: drop the `//` markers and the folded comma separators
    static func cleanComment(_ raw: String) -> [String] {
        let strip = CharacterSet(charactersIn: " ,\n\t")
        return raw.components(separatedBy: "//")
            .map { $0.trimmingCharacters(in: strip) }
            .filter { !$0.isEmpty }
    }

    /// `/pattern/` reads as the bare pattern
    static func unslash(_ text: String) -> String {
        guard text.count > 1, text.hasPrefix("/"), text.hasSuffix("/") else {
            return text
        }
        return String(text.dropFirst().dropLast())
    }

    /// json array literal for a javascript argument
    static func jsList(_ names: [String]) -> String {
        let data = (try? JSONEncoder().encode(names)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// json array literal of node ids for a javascript argument
    static func jsInts(_ ids: [Int]) -> String {
        "[" + ids.map(String.init).joined(separator: ",") + "]"
    }

    /// json string literal, quotes included
    static func jsText(_ text: String) -> String {
        let list = jsList([text])
        return String(list.dropFirst().dropLast())
    }
}
#endif
