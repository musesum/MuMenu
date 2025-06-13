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

public struct LeafSearchView: View {
    @ObservedObject var leafVm: LeafSearchVm
    public init(leafVm: LeafSearchVm) { self.leafVm = leafVm }
    public var body: some View {
        VStack(spacing: 16) {
            Text("Voice Search")
                .font(.headline)
            Text(leafVm.transcript.isEmpty ? "Say a menu command..." : leafVm.transcript)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
            if leafVm.isListening {
                ProgressView("Listening...")
            }
            Button(action: {
                leafVm.isListening ? leafVm.stopListening() : leafVm.startListening()
            }) {
                Image(systemName: leafVm.isListening ? "mic.fill" : "mic")
                    .font(.largeTitle)
                    .padding()
            }
            .background(leafVm.isListening ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
            .clipShape(Circle())
            if !leafVm.predictedMenuPath.isEmpty {
                Text(leafVm.predictedMenuPath)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

//#Preview {
//    LeafSearchView(vm: LeafSearchVm(...))
//}
