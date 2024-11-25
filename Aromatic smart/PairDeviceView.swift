// Updated PairDeviceView.swift

import SwiftUI
import CoreBluetooth

struct PairDeviceView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showConnectionAlert: Bool = false
    @State private var connectionAlertMessage: String = ""
    @State private var selectedDevice: CBPeripheral? = nil
    @State private var isDeviceDetailsPresented = false

    var body: some View {
        NavigationView {
            VStack {
                if bluetoothManager.isScanning {
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
                } else if bluetoothManager.discoveredDevices.isEmpty {
                    // Improved empty state
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
                                    .foregroundColor(bluetoothManager.isConnected(to: device) ? .green : .red)
                            }
                        }
                    }
                }
                .sheet(isPresented: $isDeviceDetailsPresented) {
                    if let device = selectedDevice {
                        DeviceDetailsView(device: device, bluetoothManager: bluetoothManager)
                    }
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        guard bluetoothManager.state == .poweredOn else {
                            showErrorAlert = true
                            errorMessage = "Bluetooth is not powered on. Please enable Bluetooth."
                            return
                        }
                        bluetoothManager.startScanning()
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        .onChange(of: isDeviceDetailsPresented) { isPresented in
            if isPresented {
                bluetoothManager.stopScanning()
            }
        }
        
        
        
        .onAppear {
            if bluetoothManager.state == .poweredOn {
                bluetoothManager.startScanning()
            } else {
                showErrorAlert = true
                errorMessage = "Bluetooth is not powered on. Please enable Bluetooth."
            }
        }
        .onDisappear {
            bluetoothManager.stopScanning()
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showConnectionAlert) {
            Alert(title: Text("Connection Status"),
                  message: Text(connectionAlertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
}



// Custom Waiting Animation View
struct LoadingAnimationView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7) // Create a partial circle
            .stroke(Color.blue, lineWidth: 5) // Style the stroke
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0)) // Rotate the partial circle
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating) // Infinite spinning
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
    }
}





// Preview
struct PairDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        PairDeviceView()
    }
}



struct DeviceDetailsView: View {
    var device: CBPeripheral
    @ObservedObject var bluetoothManager: BluetoothManager
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
                // **Connect Button**
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
                // Automatically send pairing password
                Text("Pairing in progress...")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()

                // Show a spinner or placeholder for pairing status
                LoadingAnimationView()
                    .frame(width: 100, height: 100)
                    .padding()

                Spacer()
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // Automatically send the pairing password when the device is connected
            if bluetoothManager.isConnected(to: device) {
                let defaultPassword = "8888"
                bluetoothManager.sendPairingPassword(peripheral: device, customCode: "1234")
            }
        }
        .onReceive(bluetoothManager.$pairingResultMessage) { message in
            if message != nil {
                showPairingResultAlert = true
            }
        }
        .alert(isPresented: $showPairingResultAlert) {
            Alert(title: Text("Pairing Result"),
                  message: Text(bluetoothManager.pairingResultMessage ?? ""),
                  dismissButton: .default(Text("OK"), action: {
                      bluetoothManager.pairingResultMessage = nil
                  }))
        }
    }
}
