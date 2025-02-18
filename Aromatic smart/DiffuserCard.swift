import SwiftUI
import SwiftData

struct DiffuserCard: View {
    @State private var isEditing = false  // Tracks if the name is being edited
    @State private var editedName: String // Stores the edited name
    let diffuser: Diffuser
    @EnvironmentObject var diffuserManager: DiffuserManager

    init(diffuser: Diffuser) {
        self.diffuser = diffuser
        _editedName = State(initialValue: diffuser.name)  // Initialize with the diffuser's name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Editable Name and Connection Status
            HStack {
                if isEditing {
                    TextField("Enter Device name", text: $editedName, onCommit: {
                        diffuser.name = editedName
                        isEditing = false  // Save changes and exit edit mode
                    })
                    .font(Font.custom("DIN Next LT Arabic", size: 18))
                    .foregroundColor(.black)
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(diffuser.name)
                        .font(Font.custom("DIN Next LT Arabic", size: 22))
                        .foregroundColor(.white)
                }

                Button(action: {
                    isEditing.toggle()
                    if !isEditing {
                        diffuser.name = editedName  // Save the name when exiting edit mode
                    }
                }) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .foregroundColor(.white)
                        .imageScale(.large)
                }

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: diffuser.isConnected ? "wifi" : "wifi.slash")
                        .foregroundColor(diffuser.isConnected ? .green : .red)
                        .font(.system(size: 20))
                    
                    Text(diffuser.isConnected ? "Connected" : "Desconnected")
                        .font(Font.custom("DIN Next LT Arabic", size: 16))
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    if !diffuser.isConnected, let peripheralUUID = diffuser.peripheralUUID {
                        print("🔄 Attempting to reconnect to \(diffuser.name)...")
                        diffuserManager.reconnectToPeripheral(with: peripheralUUID) { result in
                            switch result {
                            case .success(let peripheral):
                                print("✅ Successfully reconnected to \(peripheral.name ?? "Unnamed Device")")
                                diffuser.isConnected = true // Update the connection status
                            case .failure(let error):
                                print("❌ Failed to reconnect: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                
                
                
            }

            // Centered Image with proper frame and padding
            HStack {
                Spacer()
                Image("AF300")
                    
                    
                    .frame(height: 160)  // Fixed height to match Figma
                    .frame(width: 263)
                    .padding(.bottom, 5)  // Extra padding to prevent clipping
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
                Spacer()
            }

            // Model Number and Details
            Text("Model : \(diffuser.modelNumber)")
                .font(Font.custom("DIN Next LT Arabic", size: 18))
                .foregroundColor(.white)

            // Timing Configurations Navigation Link
            NavigationLink(destination: TimingsView(peripheralUUID: diffuser.peripheralUUID ?? "UnknownUUID")) {
                Text("Timing Configurations")
                    .bold()
                    .font(Font.custom("DIN Next LT Arabic", size: 18))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }

            // Remove Device Button
            Button(action: {
                diffuserManager.removeDiffuser(diffuser)
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Delete Device")
                        .font(Font.custom("DIN Next LT Arabic", size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(18)
        .background(Color(red: 0.102, green: 0.259, blue: 0.541))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        /*.onAppear {
            diffuserManager.attemptReconnectionForAllSavedDiffusers()
        } */ // 🚀 Call reconnection function when the view appears
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Text(title)
                .bold()
                .font(Font.custom("DIN Next LT Arabic", size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(subtitle)
                .font(Font.custom("DIN Next LT Arabic", size: 16))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct DiffuserCard_Previews: PreviewProvider {
    static var previews: some View {
        let dummyDiffuser = Diffuser(
            name: "جهاز الصالة",
            isConnected: true,
            modelNumber: "AF300S",
            serialNumber: "1D962844-B8DC-664B-FC8E-81BD01123D4A",
            timerSetting: 120
        )

        let dummyBluetoothManager = BluetoothManager()
        let dummyDiffuserManager = DiffuserManager(
            context: try! ModelContainer(for: Diffuser.self).mainContext,
            bluetoothManager: dummyBluetoothManager,
            diffuserAPI: dummyBluetoothManager.diffuserAPI!
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
