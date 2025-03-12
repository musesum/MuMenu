// created by musesum on 10/7/24

import SwiftUI
import MuFlo // ArchivePickerView, NextFrame

struct LeafArchiveView: View {

    @ObservedObject var leafVm: LeafArchiveVm
    
    var panelVm: PanelVm { leafVm.panelVm }
    @State private var showSettings = false
    @State private var settingsDetent = PresentationDetent.medium
    @State var title: String = "Title"
    @State var description: String = "Description"

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    //LeafArchivePlusView
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    LeafHeaderTitleView(leafVm, inset: -64)
                    Spacer()
                }
                LeafBezelView(leafVm, .none) {
                    ArchivePickerView()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            PickerModalView(leafVm)
            .presentationDetents(
                [.medium],
                selection: $settingsDetent
            )
        }
    }
}

struct PickerModalView: View {

    var leafArchiveVm: LeafArchiveVm
    @State var title: String = ""
    @State var description: String = ""
    @Environment(\.presentationMode) var presentationMode

    init(_ leafArchiveVm: LeafArchiveVm) {
        self.leafArchiveVm = leafArchiveVm
        NextFrame.shared.pause = true
        let date = Date().description.titleCase()
        self.title = "My Snapshot \(date)"
        self.description = date
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Enter title", text: $title)
                }
                Section(header: Text("Description")) {
                    TextField("Enter description", text: $description)
                }
            }
            .navigationBarTitle("Create a Mū", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
                NextFrame.shared.pause = false
            }, trailing: Button("Save") {
                presentationMode.wrappedValue.dismiss()
                NextFrame.shared.pause = false
                ArchiveVm.shared.archiveProto?.saveArchive(title, description) {
                    print("saved\n archive: \(title)\n description: \(description)")
                }
            })
        }
    }
}
