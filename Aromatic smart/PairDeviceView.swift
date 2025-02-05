import SwiftUI
import CoreBluetooth

// MARK: - PairDeviceView
struct PairDeviceView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    // MARK: - State Properties
    @State private var isLoading = true  // Controls spinner visibility
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // For navigation dismissal
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.122, green: 0.251, blue: 0.565), // Darker blue
                    Color(red: 0.542, green: 0.678, blue: 1)       // Lighter blue
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            dotsBackground
            
            VStack(spacing: 20) {
                LoadingAnimationView()
                    .padding(.top, 30)  // Adjust top spacing
                Spacer()  // Pushes content below the logo
            }
            
            VStack(spacing: 20) {
                if isLoading {
                    // Loading Animation and Info
                    VStack(spacing: 8) {
                        Text("جاري البحث عن الأجهزة ...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("تأكد من أن جهازك قيد التشغيل وقابل للاكتشاف")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                } else if bluetoothManager.discoveredDevices.isEmpty {
                    // Message when no devices are found after scanning
                    Text("لم يتم العثور على أجهزة")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // List of Devices (ScrollView + VStack)
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { peripheral in
                            deviceRow(peripheral: peripheral)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.top, 80)
            .padding(.bottom, 20)
        }
        // Start/stop scanning & error handling
        .onAppear { startScanning() }
        .onDisappear { bluetoothManager.stopScanning() }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")))
        }
        // Listen for successful pairing, then dismiss
        .onReceive(bluetoothManager.$pairingResultMessage) { message in
            if let msg = message, msg.contains("successful") {
                dismiss() // Navigate back once pairing is successful
            }
        }
    }
    
    // MARK: - Scanning Logic
    private func startScanning() {
        isLoading = true  // Show spinner when scanning starts
        bluetoothManager.startScanning()
        
        // Automatically stop spinner after 5s if at least one device is discovered
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if !bluetoothManager.discoveredDevices.isEmpty {
                isLoading = false
            }
        }
    }

    // MARK: - DeviceRow as a View Builder
    @ViewBuilder
    private func deviceRow(peripheral: CBPeripheral) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(peripheral.name ?? "جهاز غير معروف")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(bluetoothManager.deviceStatus(for: peripheral))
                    .font(.subheadline)
                    .foregroundColor(bluetoothManager.isConnected(to: peripheral) ? .green : .red)
            }
            Spacer()
            
            if !bluetoothManager.isPairedAndConnected(peripheral) {
                Button("اتصال") {
                    bluetoothManager.connect(peripheral)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text("متصل")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Background Gradient and Dots
private var dotsBackground: some View {
    ZStack {
        // Green dot
        Circle()
            .fill(Color.green)
            .frame(width: 4, height: 4)
            .offset(x: -100, y: -50)
        
        // Yellow dot (small)
        Circle()
            .fill(Color.yellow)
            .frame(width: 8, height: 8)
            .offset(x: -60, y: -10)
        
        // Blue dot
        Circle()
            .fill(Color(red: 0.67, green: 1.0, blue: 1.0))  // #7FFCAA - Light Blue
            .frame(width: 4, height: 4)
            .offset(x: 1, y: 5)
        
        // Pink dot (small)
        Circle()
            .fill(Color(red: 1.0, green: 0.67, blue: 0.67))  // #FF7CAA - Pink
            .frame(width: 10, height: 10)
            .offset(x: 60, y: -25)
    }
}

// MARK: - LoadingAnimationView
struct LoadingAnimationView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(2.5, anchor: .center)  // Enlarges the spinner
    }
}

extension BluetoothManager {
    func isPairedAndConnected(_ peripheral: CBPeripheral) -> Bool {
        let connected = isConnected(to: peripheral)
        let paired = pairingResultMessage?.contains("successful") == true
        return connected && paired
    }
}
