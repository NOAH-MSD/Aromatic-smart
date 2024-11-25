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
    let validStartBytes: Set<UInt8> = [
        0x8f, 0x0f, 0x40, 0x41, 0x21, 0x81, 0x01, 0x42, 0x22, 0xC2, 0xA2,
        0x85, 0x05, 0x43, 0xC3, 0x23, 0xA3, 0x86, 0x87, 0x44, 0xC4, 0x45,
        0xC5, 0x84, 0x46, 0xC6, 0x47, 0xC7, 0x03, 0x83, 0x4a, 0x48, 0xC8,
        0x4b, 0xcb, 0x41, 0x21
    ]
    
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
    
    
    func sendPairingPassword(peripheral: CBPeripheral, customCode: String) {
        let defaultPassword = "8888" // Hardcoded password
        // Attempt pairing using the old protocol
        sendOldProtocolPassword(password: defaultPassword, peripheral: peripheral)

        // Wait for a response and retry with the new protocol if necessary
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            if let pairingResult = self.pairingResultMessage {
                if pairingResult.contains("V2.0") {
                    print("Old protocol pairing successful.")
                    // Request data after successful pairing
                    self.requestDataFromDevice(peripheral: peripheral)
                } else {
                    print("Old protocol failed. Attempting new protocol...")
                    self.sendNewProtocolPassword(password: defaultPassword, customCode: customCode, peripheral: peripheral)
                }
            } else {
                print("No response. Attempting new protocol...")
                self.sendNewProtocolPassword(password: defaultPassword, customCode: customCode, peripheral: peripheral)
            }
        }
    }
    
    func requestEquipmentVersion(peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Characteristic not found.")
            return
        }
        
        let command = Data([0x87]) // Command to request equipment version
        peripheral.writeValue(command, for: characteristic, type: .withResponse)
        print("Sent 0x87 command to request equipment version.")
    }
    
    func requestDataFromDevice(peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Characteristic not found.")
            return
        }
        let command = Data([0x40]) // Command to request data packets
        peripheral.writeValue(command, for: characteristic, type: .withResponse)
        print("Sent 0x40 command to request data packets.")
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
    
    func parseCombinedData(_ data: Data) {
        if let asciiString = String(data: data, encoding: .ascii) {
            print("ASCII Data: \(asciiString)")
        } else {
            print("Data contains non-ASCII bytes.")
        }

        // Example: Extract specific bytes
        let packetHeader = data.prefix(2) // First 2 bytes
        print("Packet Header: \(packetHeader.map { String(format: "%02x", $0) }.joined())")

        let restOfData = data.dropFirst(2) // Skip the first 2 bytes
        print("Remaining Data: \(restOfData.map { String(format: "%02x", $0) }.joined())")
    }
    
    func processReceivedData(_ packets: [Data]) {
        // Combine packets
        let combinedData = packets.reduce(Data()) { $0 + $1 }
        print("Combined Data: \(combinedData.map { String(format: "%02x", $0) }.joined())")

        // Further processing
        parseCombinedData(combinedData)
    }
    
    func parseResponse(_ data: Data) {
        guard data.count > 1 else {
            print("Invalid response: Data too short.")
            return
        }

        // Extract the start byte
        let startByte = data[0]

        // Validate the start byte against the registered list
        guard validStartBytes.contains(startByte) else {
            print("Unknown start byte: 0x\(String(format: "%02x", startByte)). Ignoring response.")
            return
        }

        // Handle responses based on the start byte
        switch startByte {
        case 0x8f:
            print("Authentication Response:")
            parseAuthenticationResponse(data)

        case 0x40:
            print("Data Packet Response:")
            parseDataPacketResponse(data)

        case 0x87:
            print("Equipment Version Response:")
            parseEquipmentVersionResponse(data)

        case 0x42, 0x43:
            print("General Device Status Response:")
            parseGeneralStatusResponse(data)

        case 0x46:
            print("Grade Limits Response:")
            parseGradeLimitsResponse(data)
            
        case 0x45:
            print("Machine Model Response:")
            parseMachineModelResponse(data)
            
        case 0x4a:
            print("Fragrance Timing Response:")
            parseFragranceTimingResponse(data)
            
        case 0x47, 0xC7:
            print("Grade Timing Response:")
            parseGradeTimingResponse(data)
            
        case 0x48 :
            print("Fragrance Names Response:")
            parseFragranceNamesResponse(data)
        
        case 0x4b,0xcb :
            print("Essential Oil Status Response:")
            parseEssentialOilStatusResponse(data)
            
        case 0xC1, 0x41:
            print("Clock Response:")
            parseClockResponse(data)
            
        default:
            print("Unhandled Response Type (Start Byte: 0x\(String(format: "%02x", startByte))):")
            parseGenericResponse(data)
        }
    }
    
    func parseAuthenticationResponse(_ data: Data) {
        let asciiPart = data[1...]
        if let decodedString = String(data: asciiPart, encoding: .ascii) {
            print("ASCII Data: \(decodedString)")
        } else {
            print("Failed to decode authentication response.")
        }
    }
    
    func parseDataPacketResponse(_ data: Data) {
        guard data.count >= 2 else {
            print("Invalid Data Packet Response: Data too short.")
            return
        }

        // First byte indicates the command (already handled in the switch)
        let packetCount = Int(data[1]) // Second byte is the number of packets
        print("Packet Count: \(packetCount)")

        // Log the remaining data (if applicable)
        let additionalData = data.dropFirst(2)
        if !additionalData.isEmpty {
            print("Additional Data: \(additionalData.map { String(format: "0x%02x", $0) }.joined(separator: " "))")
        }
    }
    
    func parseEquipmentVersionResponse(_ data: Data) {
        guard data.count > 1 else {
            print("Invalid Equipment Version Response: Data too short.")
            return
        }

        let versionData = data.dropFirst() // Remove the start byte
        if let versionString = String(data: versionData, encoding: .ascii) {
            print("Equipment Version: \(versionString)")
        } else {
            print("Failed to decode equipment version.")
        }
    }
    
    
    
    func parseGradeLimitsResponse(_ data: Data) {
        guard data.count >= 11 else {
            print("Invalid Grade Limits Response: Data too short.")
            return
        }
        
        // Extract fields
        let maxGrade = data[1]
        let minCustomGradeWorking = UInt16(data[2]) << 8 | UInt16(data[3]) // Combine D2, D3
        let maxCustomGradeWorking = UInt16(data[4]) << 8 | UInt16(data[5]) // Combine D4, D5
        let minCustomGradePause = UInt16(data[6]) << 8 | UInt16(data[7])   // Combine D6, D7
        let maxCustomGradePause = UInt16(data[8]) << 8 | UInt16(data[9])   // Combine D8, D9
        let numberOfFragrances = data[10]
        let numberOfLightModes = data[11]

        // Print parsed values
        print("Grade Limits Response:")
        print("Max Grade: \(maxGrade)")
        print("Min Custom Grade Working: \(minCustomGradeWorking)")
        print("Max Custom Grade Working: \(maxCustomGradeWorking)")
        print("Min Custom Grade Pause: \(minCustomGradePause)")
        print("Max Custom Grade Pause: \(maxCustomGradePause)")
        print("Number of Fragrances: \(numberOfFragrances)")
        print("Number of Atmosphere Light Modes: \(numberOfLightModes)")
    }
    
    func parseMachineModelResponse(_ data: Data) {
        guard data.count > 1 else {
            print("Invalid Machine Model Response: Data too short.")
            return
        }

        // Drop the start byte (0x45) and decode the rest as ASCII
        let modelData = data.dropFirst()
        if let modelString = String(data: modelData, encoding: .ascii) {
            print("Machine Model: \(modelString)")
        } else {
            print("Failed to decode machine model response.")
        }
    }
    
    func parseFragranceTimingResponse(_ data: Data) {
        guard data.count >= 17 else {
            print("Invalid Fragrance Timing Response: Data too short.")
            return
        }
        // Extract fields
        let fragranceType = data[1]
        let timingBytes = data[2]
        let switches = data[3]
        let atomizationSwitch = switches & 0x01
        let fanSwitch = (switches >> 1) & 0x01
        let currentTiming = data[4]
        let timingNumber = data[5]
        let timingSettings = data[6]
        let powerOnHour = data[7]
        let powerOnMinute = data[8]
        let powerOffHour = data[9]
        let powerOffMinute = data[10]
        let daysOfWeek = data[11]
        let gradeMode = data[12]
        let grade = data[13]
        let customWorkTime = UInt16(data[14]) << 8 | UInt16(data[15]) // Combine D14, D15
        let customPauseTime = UInt16(data[16]) << 8 | UInt16(data[17]) // Combine D16, D17

        // Decode days of the week
        let days = [
            (daysOfWeek & 0x01) != 0 ? "Sunday" : nil,
            (daysOfWeek & 0x02) != 0 ? "Monday" : nil,
            (daysOfWeek & 0x04) != 0 ? "Tuesday" : nil,
            (daysOfWeek & 0x08) != 0 ? "Wednesday" : nil,
            (daysOfWeek & 0x10) != 0 ? "Thursday" : nil,
            (daysOfWeek & 0x20) != 0 ? "Friday" : nil,
            (daysOfWeek & 0x40) != 0 ? "Saturday" : nil
        ].compactMap { $0 }.joined(separator: ", ")

        // Print parsed values
        print("Fragrance Timing Response:")
        print("Fragrance Type: \(fragranceType)")
        print("Timing Bytes: \(timingBytes)")
        print("Atomization Switch: \(atomizationSwitch == 1 ? "On" : "Off")")
        print("Fan Switch: \(fanSwitch == 1 ? "On" : "Off")")
        print("Current Timing Number: \(currentTiming)")
        print("Timing Number: \(timingNumber)")
        print("Power On: \(String(format: "%02d:%02d", powerOnHour, powerOnMinute))")
        print("Power Off: \(String(format: "%02d:%02d", powerOffHour, powerOffMinute))")
        print("Days of Operation: \(days)")
        print("Grade Mode: \(gradeMode == 1 ? "Custom" : "Default")")
        print("Grade: \(grade)")
        print("Custom Work Time: \(customWorkTime) seconds")
        print("Custom Pause Time: \(customPauseTime) seconds")
    }
    
    func parseGradeTimingResponse(_ data: Data) {
        guard data.count >= 20 else {
            print("Invalid Grade Timing Response: Data too short.")
            return
        }

        // Each grade has a pair of values: working time (2 bytes) and pause time (2 bytes).
        let gradeCount = 10
        var gradeTimings: [(workTime: UInt16, pauseTime: UInt16)] = []

        for gradeIndex in 0..<gradeCount {
            let workTimeIndex = 1 + (gradeIndex * 4) // Offset by 1 for the start byte, each grade has 4 bytes
            let pauseTimeIndex = workTimeIndex + 2

            // Ensure we have enough data to extract this grade's timing
            guard pauseTimeIndex + 1 < data.count else {
                print("Insufficient data for grade \(gradeIndex + 1).")
                return
            }

            // Extract working time and pause time for the grade
            let workTime = UInt16(data[workTimeIndex]) << 8 | UInt16(data[workTimeIndex + 1])
            let pauseTime = UInt16(data[pauseTimeIndex]) << 8 | UInt16(data[pauseTimeIndex + 1])
            gradeTimings.append((workTime: workTime, pauseTime: pauseTime))
        }

        // Print parsed timings
        print("Grade Timing Response:")
        for (index, timing) in gradeTimings.enumerated() {
            print("Grade \(index + 1): Work Time = \(timing.workTime) seconds, Pause Time = \(timing.pauseTime) seconds")
        }
    }
    
    func parseFragranceNamesResponse(_ data: Data) {
        guard data.count >= 64 else {
            print("Invalid Fragrance Names Response: Data too short.")
            return
        }

        // Initialize an array to hold the fragrance names
        var fragranceNames: [String] = []

        // Loop through the 4 fragrance name slots
        for i in 0..<4 {
            // Calculate the start and end indices for the 16-byte segment
            let startIndex = 1 + (i * 16) // Offset by 1 for the start byte
            let endIndex = startIndex + 16

            // Extract the 16-byte segment
            let fragranceData = data[startIndex..<endIndex]

            // Decode the name, trimming any null characters or padding
            if let fragranceName = String(data: fragranceData, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) {
                if !fragranceName.isEmpty {
                    fragranceNames.append(fragranceName)
                }
            }
        }

        // Print the fragrance names
        print("Fragrance Names Response:")
        for (index, name) in fragranceNames.enumerated() {
            print("Fragrance \(index + 1): \(name)")
        }
    }
    
    func parseEssentialOilStatusResponse(_ data: Data) {
        guard data.count >= 17 else {
            print("Invalid Essential Oil Status Response: Data too short.")
            return
        }

        // Extract battery level
        let batteryLevel = data[1]

        // Initialize arrays for essential oil data
        var essentialOilData: [(total: UInt16, remaining: UInt16)] = []

        // Loop through each scent (up to 4)
        for scentIndex in 0..<4 {
            let totalAmountIndex = 2 + (scentIndex * 4) // Start of total amount for this scent
            let remainingAmountIndex = totalAmountIndex + 2 // Start of remaining amount for this scent

            // Ensure we have enough data
            guard remainingAmountIndex + 1 < data.count else {
                print("Insufficient data for scent \(scentIndex + 1).")
                break
            }

            // Extract total and remaining amounts for this scent
            let totalAmount = UInt16(data[totalAmountIndex]) << 8 | UInt16(data[totalAmountIndex + 1])
            let remainingAmount = UInt16(data[remainingAmountIndex]) << 8 | UInt16(data[remainingAmountIndex + 1])
            essentialOilData.append((total: totalAmount, remaining: remainingAmount))
        }

        // Print parsed data
        print("Essential Oil Status Response:")
        print("Battery Level: \(batteryLevel)%")
        for (index, oil) in essentialOilData.enumerated() {
            print("Scent \(index + 1): Total Amount = \(oil.total), Remaining Amount = \(oil.remaining)")
        }
    }
    
    func parseClockResponse(_ data: Data) {
        guard data.count >= 8 else {
            print("Invalid Clock Response: Data too short.")
            return
        }

        // Extract fields
        let weekday = data[1]
        let year = 2000 + Int(data[2]) // Add 2000 to the 2-digit year
        let month = data[3]
        let day = data[4]
        let hour = data[5]
        let minute = data[6]
        let second = data[7]

        // Convert weekday to string
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let weekdayString = (weekday < weekdays.count) ? weekdays[Int(weekday)] : "Unknown"

        // Print parsed clock data
        print("Clock Response:")
        print("Current Time: \(String(format: "%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second))")
        print("Weekday: \(weekdayString)")
    }
    
    func parseGeneralStatusResponse(_ data: Data) {
        let asciiPart = data[1...]
        if let decodedString = String(data: asciiPart, encoding: .ascii) {
            print("General Status Data: \(decodedString)")
        } else {
            print("Failed to decode general status response.")
        }
    }
    
    func parseGenericResponse(_ data: Data) {
        let asciiPart = data[1...]
        if let decodedString = String(data: asciiPart, encoding: .ascii) {
            print("Generic ASCII Data: \(decodedString)")
        } else {
            print("Raw Data: \(data.map { String(format: "0x%02x", $0) }.joined(separator: " "))")
        }
    }
    
    func handleIncomingDataPackets(peripheral: CBPeripheral, characteristic: CBCharacteristic, packetCount: Int) {
        var receivedPackets: [Data] = [] // Store received packets

        // Handle incoming packets in `didUpdateValueFor`
        func onPacketReceived(data: Data) {
            receivedPackets.append(data)
            print("Received packet \(receivedPackets.count)/\(packetCount): \(data.map { String(format: "%02x", $0) }.joined())")

            // Parse the response for each packet
            parseResponse(data)

            // Check if all packets are received
            if receivedPackets.count == packetCount {
                print("All packets received. Processing combined data...")
                processReceivedData(receivedPackets)
            }
        }

        // Process the incoming data
        if let data = characteristic.value {
            onPacketReceived(data: data)
        }
    }
    
    
    
    
    
    
    func sendNewProtocolPassword(password: String, customCode: String, peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Pairing characteristic not found.")
            return
        }
        let command = createNewProtocolCommand(password: password, customCode: customCode)
        peripheral.writeValue(command, for: characteristic, type: .withResponse)
        print("New protocol password sent.")

        // Request data after pairing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            if let pairingResult = self.pairingResultMessage {
                if pairingResult.contains("CY_V3.0") {
                    print("New protocol pairing successful.")
                    //self.requestDataFromDevice(peripheral: peripheral)
                    //self.requestEquipmentVersion(peripheral: peripheral)
                } else {
                    print("Pairing failed: \(self.pairingResultMessage ?? "Unknown error").")
                }
            }
        }
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

            if characteristic.uuid == CBUUID(string: "FFF6") { // Replace with actual UUID
                pairingCharacteristic = characteristic
                print("Pairing characteristic found.")

                // Automatically send pairing password when characteristic is found
                let customCode = "1234" // Replace with actual custom code if needed
                sendPairingPassword(peripheral: peripheral, customCode: customCode)

                // Optionally subscribe to notifications
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading value: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            print("No data received.")
            return
        }

        // Format received data as 0x-prefixed hex values
        let hexValues = data.map { String(format: "0x%02x", $0) }.joined(separator: " ")
        print("Received data as hex: \(hexValues)")

        // Handle equipment version (response to 0x87 command)
        if data.count > 1, data[0] == 0x88 {
            let versionData = data.dropFirst() // Remove 0x88 identifier
            if let versionString = String(data: versionData, encoding: .ascii) {
                print("Equipment Version: \(versionString)")
            } else {
                print("Unable to decode equipment version.")
            }
        }

        // Handle response to 0x40 command
        if data.count >= 2, data[0] == 0x40 {
            let packetCount = Int(data[1]) // Number of packets to expect
            print("Device will send \(packetCount) data packets.")
            handleIncomingDataPackets(peripheral: peripheral, characteristic: characteristic, packetCount: packetCount)
        } else {
            // For all other responses, use parseResponse directly
            parseResponse(data)
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
