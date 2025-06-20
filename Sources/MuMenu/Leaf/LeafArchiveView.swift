// created by musesum on 10/7/24

import SwiftUI
import MuFlo // ArchivePickerView, NextFrame

struct LeafArchiveView: View {

    @ObservedObject var leafVm: LeafArchiveVm
    var panelVm: PanelVm { leafVm.panelVm }

    @State private var showPicker = false
    @State private var settingsDetent = PresentationDetent.medium
    @State var title: String = "Title"
    @State var description: String = "Description"

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    // bring up picker
                    Button {
                        showPicker.toggle()
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    LeafHeaderTitleView(leafVm, inset: 0)
                    Spacer()
                }
                LeafBezelView(leafVm, .none) {
                    ArchivePickerView(leafVm.archiveVm)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            PickerModalView(leafVm)
            .presentationDetents(
                [.medium],
                selection: $settingsDetent
            )
        }
    }
}

struct PickerModalView: View {

    let leafArchiveVm: LeafArchiveVm
    let archiveVm: ArchiveVm
    let nextFrame: NextFrame

    @State var title: String = ""
    @State var description: String = ""
    @Environment(\.presentationMode) var presentationMode

    init(_ leafArchiveVm: LeafArchiveVm) {

        self.leafArchiveVm = leafArchiveVm
        self.archiveVm = leafArchiveVm.archiveVm
        self.nextFrame = archiveVm.nextFrame
        nextFrame.pause = true
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
                nextFrame.pause = false
            }, trailing: Button("Save") {
                presentationMode.wrappedValue.dismiss()
                nextFrame.pause = false
                leafArchiveVm.archiveVm.archiveProto?.saveArchive(title, description) {
                    print("saved\n archive: \(title)\n description: \(description)")
                }
            })
        }
    }
}
