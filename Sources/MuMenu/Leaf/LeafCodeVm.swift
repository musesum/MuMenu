#if !os(watchOS)
//  created by musesum on 8/6/26

import SwiftUI
import MuFlo

/// compile diagnostic in embed-body line space
public struct CodeError: Identifiable, Hashable, Codable {
    public let id: Int
    public let line: Int
    public let col: Int
    public let message: String

    public init(_ id: Int, line: Int, col: Int, message: String) {
        self.id = id
        self.line = line
        self.col = col
        self.message = message
    }
}

/// annotated shader source editor bound to a flo embed
public class LeafCodeVm: LeafVm {

    /// app-installed compiler: (body, targetFlo, done(errors))
    nonisolated(unsafe) public static var compiler: ((String, Flo, @escaping ([CodeError]) -> Void) -> Void)?
    /// app-installed seed when the target flo has no embed yet
    nonisolated(unsafe) public static var seed: ((Flo) -> String?)?

    @Published public var errors = [CodeError]()
    @Published public var status = ""
    @Published public var dirty = false

    public var runScript: ((String) -> Void)?                    /// js in, set by view
    public var readCode: ((@escaping (String) -> Void) -> Void)? /// js getValue, set by view

    /// node whose embed is edited: the flo declaring `{{ }}`, else `target "a.b.c"`
    public lazy var embedFlo: Flo? = {
        if menuTree.flo.embed != nil { return menuTree.flo }
        guard let path = menuTree.flo.getExpr("target") as? String else { return nil }
        return menuTree.flo.getRoot().findPath(path)
    }()

    public var code: String {
        if let embedFlo {
            if let str = embedFlo.embed?.getVal() as? String { return str }
            if let seeded = Self.seed?(embedFlo) { return seeded }
        }
        return ""
    }

    /// push code plus current annotations into a freshly loaded page,
    /// resuming the text and undo stack left behind by an earlier session
    public func loadPage() {
        let body = code
        if let stash = readStash(), stash.base == body {
            runScript?("loadCode(\(Self.jsText(stash.text)), \(Self.jsText(stash.history)))")
            dirty = stash.text != body
        } else {
            clearStash() // the flo moved on; its stack no longer maps
            runScript?("loadCode(\(Self.jsText(body)))")
            dirty = false
        }
        applyErrors()
    }

    //  MARK: - stash

    /// editor state that outlives the leaf: the text as last shown, its
    /// CodeMirror history, and the flo body both were measured against
    private struct CodeStash: Codable {
        let base: String
        let text: String
        let history: String
    }
    /// a runaway stack is not worth the defaults store
    private static let stashMost = 256 * 1024

    private var stashKey: String? {
        guard let embedFlo else { return nil }
        return "MuMenu.code." + embedFlo.path()
    }

    /// the page hands out text plus stack once per edit burst
    public func applyCodeStash(_ text: String, _ history: String) {
        writeStash(CodeStash(base: code, text: text, history: history))
    }

    /// a compile makes the submitted body the new baseline; the stack stands
    private func rebaseStash(_ body: String) {
        writeStash(CodeStash(base: body, text: body,
                             history: readStash()?.history ?? ""))
    }

    private func readStash() -> CodeStash? {
        guard let stashKey,
              let data = UserDefaults.standard.data(forKey: stashKey)
        else { return nil }
        return try? JSONDecoder().decode(CodeStash.self, from: data)
    }

    private func writeStash(_ stash: CodeStash) {
        guard let stashKey,
              let data = try? JSONEncoder().encode(stash)
        else { return }
        if data.count > Self.stashMost { return clearStash() }
        UserDefaults.standard.set(data, forKey: stashKey)
    }

    private func clearStash() {
        if let stashKey {
            UserDefaults.standard.removeObject(forKey: stashKey)
        }
    }

    public func submit() {
        guard let embedFlo else { return status = "no embed target" }
        guard let compiler = Self.compiler else { return status = "no compiler installed" }
        guard let readCode else { return status = "editor not loaded" }
        status = "compiling…"
        readCode { [weak self] body in
            if body.isEmpty {
                self?.status = "editor not ready"
                return
            }
            compiler(body, embedFlo) { errors in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.errors = errors
                    if errors.isEmpty {
                        // the flo body is both what the archive saves and what
                        // the rule's own closure recompiles on its next touch,
                        // so an undone tweak left here swaps itself back in.
                        // An unedited body equals the template, so it carries
                        // no delta and stays out of archives on its own
                        embedFlo.setEmbed(body)
                        self.rebaseStash(body)
                        self.dirty = false
                        self.status = "compiled · live"
                    } else {
                        self.status = "\(errors.count) error\(errors.count == 1 ? "" : "s")"
                    }
                    self.applyErrors()
                }
            }
        }
    }

    public func undo() { runScript?("cm.undo()") }
    public func redo() { runScript?("cm.redo()") }

    /// bottom bar: 12pt labels, 5pt capsule padding, 8pt around the row
    public static let barHeight = CGFloat(40)
    /// panel floor in Menu.diameter units; the value column beside it is 4·d
    static let heightLeast = CGFloat(5)
    /// panel at rest, the aspect PanelVm hands out before any measure
    static let heightRest = CGFloat(12)

    private var pageHeight = CGFloat(0)

    /// posted content height -> panel height (LeafGraphVm aspect mechanism).
    /// The page keeps `height: 100%`, so a body past the cap goes on scrolling
    /// inside CodeMirror instead of growing the panel past the screen
    public func applyCodeHeight(_ posted: Double) {
        let want = CGFloat(posted)
        guard want > 0, want != pageHeight else { return }
        pageHeight = want
        // the page posts from inside a WKScriptMessage turn, which can land
        // while the tree is still committing a layout; publishing panel
        // geometry there is a write during an update, so take the next turn
        DispatchQueue.main.async { [weak self] in
            self?.applyPageHeight(want)
        }
    }

    private func applyPageHeight(_ want: CGFloat) {
        let screen = MenuScreen.shared.size.value.height
        let most = (screen > 0
                    ? screen - Menu.diameter2 * 2
                    : Self.heightRest * Menu.diameter)
        let tall = min(most, max(Self.heightLeast * Menu.diameter,
                                 want + Self.barHeight))
        let unit = CGSize(width: panelVm.aspectSz.width,
                          height: tall / Menu.diameter)
        guard unit.height != panelVm.aspectSz.height else { return }
        panelVm.aspectSz = unit
        branchVm.panelVm.aspectSz = unit
        refreshView()
    }

    public func applyErrors() {
        if let data = try? JSONEncoder().encode(errors),
           let json = String(data: data, encoding: .utf8) {
            runScript?("setErrors(\(json))")
        }
    }

    /// an editor that fades out mid-edit is unusable
    override public var disablesAutoFade: Bool { true }

    override public func syncVal(_ visit: Visitor) {}

    static func jsText(_ text: String) -> String {
        if let data = try? JSONEncoder().encode([text]),
           let json = String(data: data, encoding: .utf8) {
            return String(json.dropFirst().dropLast())
        }
        return "\"\""
    }
}
#endif
