// created by musesum on 6/13/25

import SwiftUI
import Speech
import MuFlo

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
