import SwiftUI
import Speech
import MuFlo

#if (os(iOS) && compiler(>=6.6) && canImport(FoundationModels)) || (os(iPadOS) && compiler(>=6.6) && canImport(FoundationModels)) || (os(visionOS) && compiler(>=6.6) && canImport(FoundationModels))
import FoundationModels

private var speechTranscriber: SpeechTranscriber? = {
    if #available(iOS 26, visionOS 2, *) {
        return SpeechTranscriber()
    } else if #available(iOS 17, visionOS 1, *) {
        return DictationTranscriber()
    } else {
        return nil
    }
}()

public class LeafSearchVm: LeafVm {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    @Published var predictedMenuPath: String = ""
    
    private var recognitionTask: Task<Void, Never>?

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
        if #available(iOS 26, visionOS 2, *) {
            DispatchQueue.main.async { self.isListening = true }
            recognitionTask = Task {
                if let transcriber = speechTranscriber as? SpeechTranscriber {
                    for await result in transcriber.transcriptions() {
                        DispatchQueue.main.async {
                            self.transcript = result.formattedString
                        }
                        if result.isFinal {
                            self.stopListening()
                            self.queryIntelligenceModel(text: self.transcript)
                        }
                    }
                }
            }
        } else if #available(iOS 17, visionOS 1, *) {
            DispatchQueue.main.async { self.isListening = true }
            recognitionTask = Task {
                if let transcriber = speechTranscriber as? DictationTranscriber {
                    for await result in transcriber.transcriptions() {
                        DispatchQueue.main.async {
                            self.transcript = result.formattedString
                        }
                        if result.isFinal {
                            self.stopListening()
                            self.queryIntelligenceModel(text: self.transcript)
                        }
                    }
                }
            }
        }
    }

    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        DispatchQueue.main.async { self.isListening = false }
    }

    private func queryIntelligenceModel(text: String) {
        // TODO: Call Intelligence Foundation model to predict menu path
        // For now, just echo text back as the predicted path
        DispatchQueue.main.async {
            self.predictedMenuPath = "Predicted path for: \(text)"
        }
    }
}

#else

public class LeafSearchVm: LeafVm {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    @Published var predictedMenuPath: String = ""

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer()

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
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else { return }
            DispatchQueue.main.async { self.isListening = true }
            self.audioEngine = AVAudioEngine()
            let inputNode = self.audioEngine!.inputNode
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = self.recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            self.recognitionTask = self.recognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    DispatchQueue.main.async { self.transcript = result.bestTranscription.formattedString }
                    if result.isFinal {
                        self.stopListening()
                        self.queryIntelligenceModel(text: self.transcript)
                    }
                }
                if error != nil {
                    self.stopListening()
                }
            }
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            self.audioEngine?.prepare()
            try? self.audioEngine?.start()
        }
    }

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        DispatchQueue.main.async { self.isListening = false }
    }

    private func queryIntelligenceModel(text: String) {
        // TODO: Call Intelligence Foundation model to predict menu path
        // For now, just echo text back as the predicted path
        DispatchQueue.main.async {
            self.predictedMenuPath = "Predicted path for: \(text)"
        }
    }
}

#endif

