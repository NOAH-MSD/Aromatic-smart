import SwiftUI
import SwiftData

// Updated DiffuserCard
struct DiffuserCard: View {
    @State private var isEditing = false // Tracks if the name is being edited
    @State private var editedName: String // Stores the edited name
    let diffuser: Diffuser
    @EnvironmentObject var diffuserManager: DiffuserManager

    init(diffuser: Diffuser) {
        self.diffuser = diffuser
        _editedName = State(initialValue: diffuser.name) // Initialize with the diffuser's name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Editable Name and Status
            HStack {
                if isEditing {
                    TextField("Enter Diffuser Name", text: $editedName, onCommit: {
                        // Save changes and exit edit mode
                        diffuser.name = editedName
                        isEditing = false
                    })
                    .font(.headline)
                    .foregroundColor(.black)
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(diffuser.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Button(action: {
                    isEditing.toggle() // Toggle editing mode
                    if !isEditing {
                        // Save the name when exiting edit mode
                        diffuser.name = editedName
                    }
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(.white)
                        .imageScale(.large)
                }
                
                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: diffuser.isConnected ? "wifi" : "wifi.slash")
                        .foregroundColor(diffuser.isConnected ? .green : .red)
                        .imageScale(.medium)
                    Text(diffuser.isConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Diffuser Image
            Image("AF300")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .cornerRadius(30)
                .shadow(radius: 4)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text("Model: \(diffuser.modelNumber)")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
            }
            

            // Navigation Links
            VStack(spacing: 10) {
                NavigationLink(destination: TimingView(peripheralUUID: diffuser.peripheralUUID ?? "UnknownUUID")) {
                    SettingsRow(title: "Timing Configurations", subtitle: "Configure Timings")
                }



                Button(action: {
                    diffuserManager.removeDiffuser(diffuser)
                }) {
                    Text("Remove Device")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(diffuser.isConnected ? Color.blue.opacity(0.9) : Color.gray.opacity(0.3))
        .cornerRadius(20)
        .shadow(radius: 4)
        .padding(.horizontal)
        .onAppear {
            print("🧭 to TimingView with peripheralUUID: \(String(describing: diffuser.peripheralUUID))")
         
        }
        
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Text(title).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(subtitle)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(8) // Reduced padding
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}


struct DiffuserCard_Previews: PreviewProvider {
    static var previews: some View {
        // Dummy Diffuser
        let dummyDiffuser = Diffuser(
            name: "Living Room Diffuser",
            isConnected: true,
            modelNumber: "AF300",
            serialNumber: "1D962844-B8DC-664B-FC8E-81BD01123D4A",
            timerSetting: 120
        )
        
        // Dummy DiffuserManager (if needed)
        let dummyBluetoothManager = BluetoothManager()
        let dummyDiffuserManager = DiffuserManager(
            context: try! ModelContainer(for: Diffuser.self).mainContext,
            bluetoothManager: dummyBluetoothManager
        )

        return NavigationView {
            DiffuserCard(diffuser: dummyDiffuser)
                .environmentObject(dummyDiffuserManager)
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color(UIColor.systemBackground))
        }
    }
}
