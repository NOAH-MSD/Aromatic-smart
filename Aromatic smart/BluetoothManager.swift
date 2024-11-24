import CoreBluetooth
import SwiftUI

class BluetoothManager: NSObject, ObservableObject {
    // Published properties for real-time updates
    @Published var discoveredDevices: [CBPeripheral] = [] // List of discovered devices
    @Published var isScanning: Bool = false               // Scanning state
    @Published var state: CBManagerState = .unknown       // Bluetooth state
    @Published var showConnectionAlert: Bool = false      // Show connection alert
    @Published var connectionAlertMessage: String = ""    // Connection alert message
    @Published var pairingResultMessage: String? = nil
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var pairingCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        state = centralManager.state
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for Bluetooth devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on.")
            return
        }
        isScanning = true
        discoveredDevices = [] // Reset the list of discovered devices
        centralManager.scanForPeripherals(withServices: [CBUUID(string: "FFF0")]  , options: nil)
        print("Scanning started...")
    }
    
    /// Stop scanning for Bluetooth devices
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        print("Scanning stopped.")
    }
    
    /// Connect to a specific peripheral
    func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        peripheral.delegate = self // Set delegate to handle peripheral updates
        print("Connecting to \(peripheral.name ?? "Unknown")...")
    }
    
    /// Check if a specific peripheral is connected
    func isConnected(to device: CBPeripheral) -> Bool {
        return connectedPeripheral?.identifier == device.identifier
    }
    
    /// Format the name of a Bluetooth device
    func formatPeripheralName(_ name: String?) -> String {
        return name ?? "Unnamed Device"
    }
    
    /// Get connection status for a device
    func deviceStatus(for device: CBPeripheral) -> String {
        return isConnected(to: device) ? "Connected" : "Not Connected"
    }
    
    
    func sendPairingPassword(password: String, peripheral: CBPeripheral, customCode: String) {
        // Attempt pairing using the old protocol
        sendOldProtocolPassword(password: password, peripheral: peripheral)

        // Wait for a response and retry with the new protocol if necessary
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if let pairingResult = self.pairingResultMessage {
                if pairingResult.contains("V2.0") {
                    print("Old protocol pairing successful.")
                } else {
                    print("Old protocol failed. Attempting new protocol...")
                    self.sendNewProtocolPassword(password: password, customCode: customCode, peripheral: peripheral)
                }
            } else {
                print("No response. Attempting new protocol...")
                self.sendNewProtocolPassword(password: password, customCode: customCode, peripheral: peripheral)
            }
        }
    }
    
    
    
    
    
    
    
    
    
    func sendOldProtocolPassword(password: String, peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Pairing characteristic not found.")
            return
        }
        let command = createOldProtocolCommand(password: password)
        peripheral.writeValue(command, for: characteristic, type: .withResponse)
        print("Old protocol password sent.")
    }
    
    func sendNewProtocolPassword(password: String, customCode: String, peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Pairing characteristic not found.")
            return
        }
        let command = createNewProtocolCommand(password: password, customCode: customCode)
        peripheral.writeValue(command, for: characteristic, type: .withResponse)
        print("New protocol password sent.")
    }
    
    private func createOldProtocolCommand(password: String) -> Data {
        var commandData = Data([0x8F])
        if let passwordData = password.data(using: .ascii) {
            commandData.append(passwordData)
        }
        return commandData
    }
    
    
    
    private func createNewProtocolCommand(password: String, customCode: String) -> Data {
        var commandData = Data([0x8F])
        if let passwordData = password.data(using: .ascii),
           let customCodeData = customCode.data(using: .ascii) {
            commandData.append(passwordData)
            commandData.append(customCodeData)
        }
        return commandData
    }
}
// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    // Update Bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.state = central.state // Update the published state property
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on.")
        case .poweredOff:
            print("Bluetooth is powered off.")
            stopScanning()
        case .resetting:
            print("Bluetooth is resetting.")
        case .unauthorized:
            print("Bluetooth is not authorized.")
        case .unsupported:
            print("Bluetooth is not supported.")
        case .unknown:
            print("Bluetooth state is unknown.")
        @unknown default:
            print("Unknown state.")
        }
    }

    // Handle discovered peripherals
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        print("Discovered device: \(formatPeripheralName(deviceName))")
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }

    // Handle successful connection
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Successfully connected to \(formatPeripheralName(peripheral.name))")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil) // Start discovering services

        DispatchQueue.main.async {
            self.connectionAlertMessage = "Connected to \(self.formatPeripheralName(peripheral.name))"
            self.showConnectionAlert = true
        }
    }

    // Handle disconnection
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(formatPeripheralName(peripheral.name))")
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
        }

        DispatchQueue.main.async {
            self.connectionAlertMessage = "Disconnected from \(self.formatPeripheralName(peripheral.name))"
            self.showConnectionAlert = true
        }
    }

    // Handle failed connection
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(formatPeripheralName(peripheral.name))")

        DispatchQueue.main.async {
            self.connectionAlertMessage = "Failed to connect to \(self.formatPeripheralName(peripheral.name)): \(error?.localizedDescription ?? "Unknown error")"
            self.showConnectionAlert = true
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    // Handle discovered services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Failed to discover services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    // Handle discovered characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Failed to discover characteristics: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid.uuidString)")
            // Replace "YOUR_CHARACTERISTIC_UUID" with the actual UUID
            if characteristic.uuid == CBUUID(string: "FFF0") {
                pairingCharacteristic = characteristic
                print("Pairing characteristic found.")

                // Subscribe to notifications if needed
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    // Handle characteristic value updates
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating value for characteristic \(characteristic.uuid): \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            print("No data received.")
            return
        }

        if let response = String(data: data, encoding: .ascii) {
            if response.contains("V2.0") {
                print("Old protocol pairing successful!")
                pairingResultMessage = response
            } else if response.contains("CY_V3.0") {
                print("New protocol pairing successful!")
                pairingResultMessage = response
            } else if response.contains("ERROR") {
                print("Pairing failed: \(response)")
                pairingResultMessage = "Pairing failed."
            } else {
                print("Unknown response: \(response)")
                pairingResultMessage = response
            }
        } else {
            print("Unable to decode data.")
        }
    }

    // Handle write confirmations
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing value to characteristic \(characteristic.uuid): \(error.localizedDescription)")
        } else {
            print("Successfully wrote value to characteristic \(characteristic.uuid)")
        }
    }
}
