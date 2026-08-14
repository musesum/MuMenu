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

    /// push code plus current annotations into a freshly loaded page
    public func loadPage() {
        runScript?("loadCode(\(Self.jsText(code)))")
        applyErrors()
        dirty = false
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
                        if body != Self.seed?(embedFlo) { // unedited template stays out of archives
                            embedFlo.setEmbed(body)
                        }
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
