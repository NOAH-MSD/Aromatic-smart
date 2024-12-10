import SwiftUI
import SwiftData

struct DiffuserCard: View {
    let diffuser: Diffuser
    @EnvironmentObject var diffuserManager: DiffuserManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // Reduced spacing
            // Header: Diffuser Name and Status
            HStack {
                Text(diffuser.name)
                    .font(.headline) // Slightly smaller font
                    .foregroundColor(.white)
                Spacer()
                VStack(spacing: 4) { // Compact spacing for connection status
                    Image(systemName: diffuser.isConnected ? "wifi" : "wifi.slash")
                        .foregroundColor(diffuser.isConnected ? .green : .red)
                        .imageScale(.medium) // Smaller image scale
                    Text(diffuser.isConnected ? "Connected" : "Disconnected")
                        .font(.caption) // Smaller font
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Diffuser Image
            Image("AF300") // Replace with actual diffuser image name
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120) // Reduced size
                .cornerRadius(30)
                .shadow(radius: 4)

            // Details in a VStack
            VStack(alignment: .leading, spacing: 4) { // Compact spacing
                Text("Model: \(diffuser.modelNumber)")
                    .font(.footnote) // Smaller font
                    .foregroundColor(.white.opacity(0.9))

                Text("Serial: \(diffuser.serialNumber)")
                    .font(.footnote) // Same styling for consistency
                    .foregroundColor(.white.opacity(0.7)) // Slightly dimmer for secondary info
            }

            // Navigation Links
            VStack(spacing: 10) { // Reduced spacing
                NavigationLink(destination: OperationCycleView(diffuser: diffuser)) {
                    SettingsRow(title: "Operation Cycles", subtitle: "1 PM to 10 PM")
                }


                Button(action: {
                    diffuserManager.removeDiffuser(diffuser)
                }) {
                    Text("Remove Device")
                        .font(.subheadline) // Slightly smaller font
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(12) // Reduced padding
        .background(diffuser.isConnected ? Color.blue.opacity(0.9) : Color.gray.opacity(0.3))
        .cornerRadius(20) // Slightly smaller corner radius
        .shadow(radius: 4) // Smaller shadow
        .padding(.horizontal)
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
        let dummyDiffuser = Diffuser(
            name: "Living Room Diffuser",
            isConnected: true,
            modelNumber: "AF300",
            serialNumber: "1D962844-B8DC-664B-FC8E-81BD01123D4A",
            timerSetting: 120
        )

        do {
            let container = try ModelContainer(for: Diffuser.self)
            let dummyBluetoothManager = BluetoothManager()
            let dummyDiffuserManager = DiffuserManager(
                context: container.mainContext,
                bluetoothManager: dummyBluetoothManager
            )

            return NavigationView {
                DiffuserCard(diffuser: dummyDiffuser)
                    .environmentObject(dummyDiffuserManager)
                    .previewLayout(.sizeThatFits)
                    .padding()
                    .background(Color(UIColor.systemBackground))
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
