import CoreBluetooth
import SwiftUI

class BluetoothManager: NSObject, ObservableObject {
    // Published properties for real-time updates
    @Published var discoveredDevices: [CBPeripheral] = [] // List of discovered devices
    @Published var isScanning: Bool = false // Scanning state

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
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
        centralManager.scanForPeripherals(withServices: nil , options: nil) // Update with actual service UUID
        //[CBUUID(string: "FFF0")]
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
        connectedPeripheral = peripheral
        print("Attempting to connect to \(peripheral.name ?? "Unknown Device")...")
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
}


extension BluetoothManager: CBCentralManagerDelegate {
    // Update Bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("Discovered device: \(formatPeripheralName(peripheral.name))")
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }

    // Handle successful connection
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Successfully connected to \(formatPeripheralName(peripheral.name))")
    }

    // Handle failed connection
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(formatPeripheralName(peripheral.name)): \(error?.localizedDescription ?? "Unknown error")")
    }

    // Handle disconnection
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(formatPeripheralName(peripheral.name))")
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
        }
    }
}
