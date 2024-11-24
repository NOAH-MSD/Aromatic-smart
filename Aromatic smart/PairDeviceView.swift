import SwiftUI






struct PairDeviceView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var diffuserManager: DiffuserManager
    @State private var name: String = ""
    @State private var modelNumber: String = ""
    @State private var serialNumber: String = ""
    @State private var timerSetting: Int = 0
    @StateObject private var bluetoothManager = BluetoothManager() // Use BluetoothManager directly

    var body: some View {
        NavigationView {
            VStack {
                if bluetoothManager.isScanning {
                    ProgressView("Scanning for devices...") // Show a loading indicator during scanning
                        .padding()
                }

                List {
                    ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                        Button(action: {
                            bluetoothManager.connect(device) // Connect to the selected device
                        }) {
                            HStack {
                                Text(bluetoothManager.formatPeripheralName(device.name)) // Format the device name
                                Spacer()
                                Text(bluetoothManager.deviceStatus(for: device)) // Show connection status
                                    .foregroundColor(bluetoothManager.isConnected(to: device) ? .green : .red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        diffuserManager.addDiffuser(
                            name: "New Device",
                            isConnected: true,
                            modelNumber: "AF400",
                            serialNumber: "SN123456",
                            timerSetting: 60
                        )
                        //bluetoothManager.startScanning() // Start scanning for devices
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        .onAppear {
            bluetoothManager.startScanning() // Automatically start scanning on view load
        }
        .onDisappear {
            bluetoothManager.stopScanning() // Stop scanning when the view disappears
        }
    }
}

// Preview
struct PairDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        PairDeviceView()
    }
}
