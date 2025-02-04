import SwiftUI
import CoreBluetooth
import SwiftData

// MARK: - PairDeviceView

struct PairDeviceView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    // MARK: - State Properties
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            // Use a ZStack to apply the background gradient behind the List.
            ZStack {
                BackgroundGradientView()
                
                List {
                    ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { peripheral in
                        DeviceRow(peripheral: peripheral)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Devices")
            .toolbar { scanButton }
        }
        .onAppear { startScanningIfNeeded() }
        .onDisappear { bluetoothManager.stopScanning() }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Toolbar Scan Button
    private var scanButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                guard bluetoothManager.state == .poweredOn else {
                    showErrorAlert = true
                    errorMessage = "Bluetooth is not powered on. Please enable Bluetooth."
                    return
                }
                bluetoothManager.startScanning()
            } label: {
                Image(systemName: "magnifyingglass")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func startScanningIfNeeded() {
        if bluetoothManager.state == .poweredOn {
            bluetoothManager.startScanning()
        } else {
            showErrorAlert = true
            errorMessage = "Bluetooth is not powered on. Please enable Bluetooth."
        }
    }
}

// MARK: - DeviceRow View

struct DeviceRow: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    var peripheral: CBPeripheral
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(peripheral.name ?? "Unknown Device")
                    .font(.headline)
                Text(bluetoothManager.deviceStatus(for: peripheral))
                    .font(.subheadline)
                    .foregroundColor(bluetoothManager.isConnected(to: peripheral) ? .green : .red)
            }
            Spacer()
            // Optionally, show a loading indicator if connecting.
            if /* bluetoothManager.isConnecting(to: peripheral) */ false {
                LoadingAnimationView()
                    .frame(width: 30, height: 30)
            }
            // If the peripheral is not yet paired and connected, show a "Connect" button.
            else if !bluetoothManager.isPairedAndConnected(peripheral) {
                Button("Connect") {
                    bluetoothManager.connect(peripheral)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            // Otherwise, show a "Connected" label.
            else {
                Text("Connected")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - BackgroundGradientView

struct BackgroundGradientView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.122, green: 0.251, blue: 0.565), // Darker blue
                Color(red: 0.542, green: 0.678, blue: 1)        // Lighter blue
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - BluetoothManager Extension

extension BluetoothManager {
    func isPairedAndConnected(_ peripheral: CBPeripheral) -> Bool {
        let connected = isConnected(to: peripheral)
        let paired = pairingResultMessage?.contains("successful") == true
        return connected && paired
    }
}

// MARK: - LoadingAnimationView

struct LoadingAnimationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7) // Create a partial circle
            .stroke(Color.blue, lineWidth: 4)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
            .onDisappear { isAnimating = false }
    }
}
