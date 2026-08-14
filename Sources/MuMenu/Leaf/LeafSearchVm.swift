#if !os(watchOS)
import SwiftUI
import Speech
import MuFlo


public class LeafSearchVm: LeafVm {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    @Published var predictedMenuPath: String = ""

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    // en-US first; device locale fallback — bare init() silently no-ops when the device locale has no recognizer
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) ?? SFSpeechRecognizer()

    override public func touchLeaf(_ : TouchState, _ : Visitor) {}
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { "Voice Search" }
    override public func syncVal(_ : Visitor) {}

    override init(_ menuTree: MenuTree,
                  _ branchVm: BranchVm,
                  _ prevVm: NodeVm?,
                  _ runTypes: [LeafRunwayType]) {
        super.init(menuTree, branchVm, prevVm, runTypes)
    }

    func startListening() {
        // TCC completion lands on a background queue; NodeVm is @MainActor — hop before touching self
        SFSpeechRecognizer.requestAuthorization { @Sendable authStatus in
            Task { @MainActor in
                guard authStatus == .authorized else { return }
                self.beginRecognition()
            }
        }
    }

    private func beginRecognition() {
        guard let recognizer, recognizer.isAvailable else {
            DebugLog { P("LeafSearchVm no speech recognizer available") }
            isListening = false
            return
        }
        isListening = true
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine!.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        // handler lands off-main; extract Sendable values, hop — the result object is not Sendable
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { @Sendable result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor in
                if let text {
                    self.transcript = text
                    if isFinal {
                        self.stopListening()
                        self.queryIntelligenceModel(text: text)
                    }
                }
                if failed {
                    self.stopListening()
                }
            }
        }
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioEngine?.prepare()
        try? audioEngine?.start()
    }

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        self.isListening = false
    }

    private func queryIntelligenceModel(text: String) {
        // TODO: Call Intelligence Foundation model to predict menu path
        // For now, just echo text back as the predicted path
       self.predictedMenuPath = "Predicted path for: \(text)"
    }
}


#endif
