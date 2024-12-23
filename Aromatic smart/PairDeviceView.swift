import SwiftUI
import CoreBluetooth
import SwiftData

/// View for scanning and pairing with a new diffuser device
struct PairDeviceView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    @EnvironmentObject var bluetoothManager: BluetoothManager

    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedDevice: CBPeripheral? = nil
    @State private var isDeviceDetailsPresented = false

    var body: some View {
        NavigationView {
            VStack {
                // 1. If scanning is in progress, show a "Loading" animation
                if bluetoothManager.isScanning {
                    scanningStateView
                }
                // 2. If not scanning but no discovered devices, show an empty state
                else if bluetoothManager.discoveredDevices.isEmpty {
                    emptyStateView
                }

                // 3. Otherwise, list discovered devices
                List {
                    ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                        Button(action: {
                            selectedDevice = device
                            isDeviceDetailsPresented = true
                        }) {
                            HStack {
                                Text(bluetoothManager.formatPeripheralName(device.name))
                                Spacer()
                                Text(bluetoothManager.deviceStatus(for: device))
                                    .foregroundColor(
                                        bluetoothManager.isConnected(to: device) ? .green : .red
                                    )
                            }
                        }
                    }
                }
                // Present DeviceDetailsView for the selected peripheral
                .sheet(isPresented: $isDeviceDetailsPresented) {
                    if let device = selectedDevice {
                        DeviceDetailsView(device: device,
                                          isPresented: $isDeviceDetailsPresented)
                    }
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // A button to trigger scanning
                    Button(action: {
                        guard bluetoothManager.state == .poweredOn else {
                            showErrorAlert = true
                            errorMessage = "Bluetooth is not powered on. Please enable Bluetooth."
                            return
                        }
                        bluetoothManager.startScanning() // Delegates to diffuserAPI?.startScanning(...)
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        // 4. When deviceDetails sheet appears, stop scanning
        .onChange(of: isDeviceDetailsPresented) { isPresented in
            if isPresented {
                bluetoothManager.stopScanning()
            }
        }
        // 5. Start scanning automatically if Bluetooth is on
        .onAppear {
            if bluetoothManager.state == .poweredOn {
                bluetoothManager.startScanning()
            } else {
                showErrorAlert = true
                errorMessage = "Bluetooth is not powered on. Please enable Bluetooth."
            }
        }
        // 6. Stop scanning when this view disappears
        .onDisappear {
            bluetoothManager.stopScanning()
        }
        // 7. Show any scanning or Bluetooth errors
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Subviews

    /// View shown while scanning is in progress
    private var scanningStateView: some View {
        VStack {
            LoadingAnimationView()
                .frame(width: 100, height: 100)
                .padding()

            Text("Scanning for devices...")
                .font(.headline)
                .padding()
                .foregroundColor(.blue)

            Text("Make sure your Bluetooth device is turned on and discoverable.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    /// View shown when not scanning & no discovered devices
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
                .padding()

            Text("No devices found.")
                .font(.headline)
                .foregroundColor(.gray)

            Button(action: {
                bluetoothManager.startScanning()
            }) {
                Text("Rescan")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

/// A custom waiting/spinning animation
struct LoadingAnimationView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7) // Create a partial circle
            .stroke(Color.blue, lineWidth: 5)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

/// View to show details for a specific discovered device
struct DeviceDetailsView: View {
    var device: CBPeripheral
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Binding var isPresented: Bool
    @State private var showPairingResultAlert: Bool = false

    var body: some View {
        VStack {
            Text("Device Details")
                .font(.largeTitle)
                .padding()

            Text("Name: \(bluetoothManager.formatPeripheralName(device.name))")
                .font(.headline)
                .padding()

            Text("UUID: \(device.identifier.uuidString)")
                .font(.subheadline)
                .padding()

            Text("Status: \(bluetoothManager.deviceStatus(for: device))")
                .font(.subheadline)
                .foregroundColor(bluetoothManager.isConnected(to: device) ? .green : .red)
                .padding()

            if !bluetoothManager.isConnected(to: device) {
                Button(action: {
                    bluetoothManager.connect(device)
                }) {
                    Text("Connect")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                Text("Pairing in progress...")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()

                LoadingAnimationView()
                    .frame(width: 100, height: 100)
                    .padding()

                Spacer()
            }

            Spacer()
        }
        .padding()
        // Once connected, try pairing automatically
        .onAppear {
            if bluetoothManager.isConnected(to: device) {
                bluetoothManager.sendPairingPassword(peripheral: device,
                                                     customCode: "1234")
            }
        }
        // If the new code still publishes to authenticationResponsePublisher,
        // we can subscribe here
        .onReceive(bluetoothManager.authenticationResponsePublisher) { response in
            if response.version.hasPrefix("CY_V3") {
                isPresented = false // Dismiss on success
            }
        }
        // Pairing result messages
        .onReceive(bluetoothManager.$pairingResultMessage) { message in
            if let msg = message {
                showPairingResultAlert = true

                // If not successful, keep the sheet open, just show an alert
                if !msg.contains("successful") {
                    print("Pairing failed: \(msg)")
                }
            }
        }
        .alert(isPresented: $showPairingResultAlert) {
            Alert(title: Text("Pairing Result"),
                  message: Text(bluetoothManager.pairingResultMessage ?? ""),
                  dismissButton: .default(Text("OK"), action: {
                      bluetoothManager.pairingResultMessage = nil
                  })
            )
        }
    }
}

// MARK: - Previews
struct PairDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a mock environment for preview
        let container = try! ModelContainer(for: Diffuser.self)
        let bluetoothManager = BluetoothManager.shared
        let diffuserManager = DiffuserManager(
            context: container.mainContext,
            bluetoothManager: bluetoothManager
        )

        PairDeviceView()
            .environmentObject(bluetoothManager)
            .environmentObject(diffuserManager)
    }
}
