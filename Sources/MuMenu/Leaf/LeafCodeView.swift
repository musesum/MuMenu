#if !os(watchOS)
//  created by musesum on 8/6/26

import SwiftUI
import WebKit
import MuFlo

struct LeafCodeView: View {

    @ObservedObject var leafVm: LeafCodeVm

    var body: some View {
        VStack(spacing: 0) {
            CodeWebView(leafVm)
            HStack(spacing: 8) {
                Text(leafVm.status)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(leafVm.errors.isEmpty ? .white.opacity(0.7) : .red)
                    .lineLimit(1)
                Spacer()
                barButton("arrow.uturn.backward") { leafVm.undo() }
                barButton("arrow.uturn.forward")  { leafVm.redo() }
                Button {
                    leafVm.submit()
                } label: {
                    Label("Compile", systemImage: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(leafVm.dirty ? 0.3 : 0.15)))
                }
            }
            .padding(8)
            .frame(height: LeafCodeVm.barHeight)
            .background(Color.black.opacity(0.9))
        }
        .cornerRadius(Menu.radius)
    }

    private func barButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.15)))
        }
    }
}

/// bundled CodeMirror page bound to the embed body
private struct CodeWebView: UIViewRepresentable {

    static let handlerName = "mucode"
    let leafVm: LeafCodeVm

    init(_ leafVm: LeafCodeVm) { self.leafVm = leafVm }

    func makeCoordinator() -> CodeWebCoordinator { CodeWebCoordinator(leafVm) }

    func makeUIView(context: Context) -> WKWebView {

        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: Self.handlerName)

        let webView = CodeWebUIView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false

        leafVm.runScript = { [weak webView] script in
            webView?.evaluateJavaScript(script, completionHandler: nil)
        }
        leafVm.readCode = { [weak webView] done in
            webView?.evaluateJavaScript("getCode()") { result, _ in
                done(result as? String ?? "")
            }
        }
        guard let url = MuMenu.bundle.url(forResource: "codemirror-embed", withExtension: "html") else {
            DebugLog { P("{} code missing codemirror-embed.html") }
            return webView
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: CodeWebCoordinator) {
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: Self.handlerName)
        coordinator.leafVm.runScript = nil
        coordinator.leafVm.readCode = nil
    }
}

/// WebKit's form accessory carries two chevrons it builds already disabled, and
/// on phone its own Done bar. The content view reads both through the web view,
/// so the two public seams below are where they are refused and replaced
private final class CodeWebUIView: WKWebView {

    #if !os(visionOS)
    /// on pad the chevrons ride the shortcut bar, not an accessory, so the item
    /// itself is what has to refuse them
    private let bareAssistant = BareAssistantItem()

    override var inputAssistantItem: UITextInputAssistantItem { bareAssistant }

    /// on phone this replaces the whole form bar; on pad it is the only bar
    override var inputAccessoryView: UIView? { doneBar }

    private lazy var doneBar: UIToolbar = {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        bar.items = [.flexibleSpace(),
                     UIBarButtonItem(image: UIImage(systemName: "checkmark"),
                                     style: .done, target: self,
                                     action: #selector(closeKeys))]
        bar.sizeToFit()
        return bar
    }()

    /// the content view holds the caret, not the web view, so the resign walks down
    @objc private func closeKeys() { endEditing(true) }
    #endif
}

#if !os(visionOS)
/// swallows the groups WebKit writes, in whatever order it writes them
private final class BareAssistantItem: UITextInputAssistantItem {
    override var leadingBarButtonGroups: [UIBarButtonItemGroup] {
        get { [] } set { }
    }
    override var trailingBarButtonGroups: [UIBarButtonItemGroup] {
        get { [] } set { }
    }
}
#endif

/// injects the embed body after load; routes dirty edits
@MainActor
final class CodeWebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

    let leafVm: LeafCodeVm

    init(_ leafVm: LeafCodeVm) { self.leafVm = leafVm }

    func webView(_ webView: WKWebView, didFinish: WKNavigation!) {
        leafVm.loadPage()
    }

    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {

        guard let body = message.body as? [String: Any] else { return }
        switch body["kind"] as? String {
        case "dirty" : leafVm.dirty = true
        case "size"  : leafVm.applyCodeHeight(body["h"] as? Double ?? 0)
        case "stash" : leafVm.applyCodeStash(body["text"] as? String ?? "",
                                             body["history"] as? String ?? "")
        default      : DebugLog { P("{} code ?\(body)") }
        }
    }
}
#endif
