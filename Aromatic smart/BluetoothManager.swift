import CoreBluetooth
import Combine

/// A protocol describing all the operations needed by a diffuser type


class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()
    // MARK: - Combine Publishers
    /// These were missing in your new code. Re-add them so DiffuserManager can subscribe.
    var authenticationResponsePublisher = PassthroughSubject<AuthenticationResponse, Never>()
    var equipmentVersionPublisher       = PassthroughSubject<EquipmentVersionResponse, Never>()
    var gradeLimitsPublisher           = PassthroughSubject<GradeLimitsResponse, Never>()
    var machineModelPublisher          = PassthroughSubject<MachineModelResponse, Never>()
    var fragranceTimingPublisher       = PassthroughSubject<FragranceTimingResponse, Never>()
    var gradeTimingPublisher           = PassthroughSubject<GradeTimingResponse, Never>()
    var fragranceNamesPublisher        = PassthroughSubject<FragranceNamesResponse, Never>()
    var essentialOilStatusPublisher    = PassthroughSubject<EssentialOilStatusResponse, Never>()
    var clockResponsePublisher         = PassthroughSubject<ClockResponse, Never>()
    var mainSwitchPublisher            = PassthroughSubject<MainSwitchResponse, Never>()
    var pcbAndEquipmentVersionPublisher = PassthroughSubject<PCBAndEquipmentVersionResponse, Never>()
    var genericResponsePublisher       = PassthroughSubject<Data, Never>()
    var ackCompletion: ((Bool) -> Void)?
    var ackTimer: Timer?

    // MARK: - Published Properties
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var isScanning: Bool = false
    @Published var connectedPeripheral: CBPeripheral?
    @Published var showConnectionAlert: Bool = false
    @Published var connectionAlertMessage: String = ""
    @Published var pairingResultMessage: String? = nil
    @Published var state: CBManagerState = .unknown
    @Published var readyToSubscribe: Bool = false
    

   


    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var centralManager: CBCentralManager!
    var pairingCharacteristic: CBCharacteristic?

    /// The currently selected DiffuserAPI (e.g., Type A). Could be swapped if you detect Type B, etc.
    var diffuserAPI: DiffuserAPI?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        state = centralManager.state

        // Possibly default to TypeA for now
        diffuserAPI = TypeADiffuserAPI(bluetoothManager: self)

        setupReadyToSubscribePublisher()
    }

    // MARK: - Public Methods
    func startScanning() {
        guard state == .poweredOn else {
            print("Bluetooth is not powered on.")
            return
        }
        isScanning = true
        discoveredDevices.removeAll()

        // Let the diffuserAPI handle scanning specifics
        diffuserAPI?.startScanning(manager: centralManager)
    }

    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        print("Scanning stopped.")
    }
    
    func formatPeripheralName(_ name: String?) -> String {
        return name ?? "Unnamed Device"
    }
    
    
    func isConnected(to device: CBPeripheral) -> Bool {
        
        return connectedPeripheral?.identifier == device.identifier
    }
    
    func deviceStatus(for device: CBPeripheral) -> String {
        return isConnected(to: device) ? "Connected" : "Not Connected"
    }
    
    func loadDeviceModel(for device: CBPeripheral) -> String {
        return diffuserAPI?.loadDeviceModel(peripheralUUID: device.identifier.uuidString) ?? "Unknown"
    }
    
    

    func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        peripheral.delegate = self
        print("Connecting to \(peripheral.name ?? "Unknown")...")
    }
    
    
    
    func sendOldProtocolPassword(password: String, to peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Error: No pairing characteristic available for old protocol password.")
            return
        }
        diffuserAPI?.sendOldProtocolPassword(peripheral: peripheral, characteristic: characteristic, password: password)
    }
    
    
    
 
    
    func sendNewProtocolPassword(password: String, customCode: String, to peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Error: No pairing characteristic available for new protocol password.")
            return
        }
        diffuserAPI?.sendNewProtocolPassword(peripheral: peripheral, characteristic: characteristic, password: password, customCode: customCode)
    }
    
    

    
    
    func sendPairingPassword(peripheral: CBPeripheral, customCode: String) {
        guard let characteristic = pairingCharacteristic else {
            print("Error: No pairing characteristic available for pairing.")
            return
        }
        print("🔐 trying to pair with device")
        diffuserAPI?.sendPairingPassword(peripheral: peripheral, characteristic: characteristic, customCode: customCode)
    }
    

    
    func parseResponse(_ data: Data) {
        diffuserAPI?.parseResponse(data)
    }

    /// Example: Expose a method to request equipment version
    func requestEquipmentVersion(peripheral: CBPeripheral) {
        diffuserAPI?.requestEquipmentVersion(peripheral: peripheral,
                                             characteristic: pairingCharacteristic)
    }
    
    func writeSettingsToDiffuser(peripheral: CBPeripheral, characteristic: CBCharacteristic, command: [UInt8]) {
        diffuserAPI?.writeAndVerifySettings(peripheral: peripheral, characteristic: characteristic, writeCommand: command)
    }
    
    func sendCurrentTimeToDiffuserAsBinary() {
        guard let characteristic = pairingCharacteristic else {
            print("Error: Pairing characteristic not available.")
            return
        }

        // Get the current date and time
        let now = Date()
        let calendar = Calendar.current

        // Extract components from the date
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekday], from: now)
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute,
              let second = components.second,
              let weekday = components.weekday else {
            print("Error: Could not extract date components.")
            return
        }

        // Validate ranges
         guard (2000...2099).contains(year),
               (1...12).contains(month),
               (1...31).contains(day),
               (0...23).contains(hour),
               (0...59).contains(minute),
               (0...59).contains(second),
               (1...7).contains(weekday) else {
             print("Error: Invalid date or time components.")
             return
         }


        
        // Inline binary conversion function
        func toBinary(_ value: Int) -> UInt8 {
            return UInt8(value) // Direct decimal representation
        }

        // Format into binary for each variable
        let yearBinary: UInt8 = toBinary(year % 100) // Last two digits of the year
        let monthBinary: UInt8 = toBinary(month)
        let dayBinary: UInt8 = toBinary(day)
        let hourBinary: UInt8 = toBinary(hour)
        let minuteBinary: UInt8 = toBinary(minute)
        let secondBinary: UInt8 = toBinary(second)

        // Debugging logs for verification
        print("Time components before binary conversion: Year: \(year % 100), Month: \(month), Day: \(day), Hour: \(hour), Minute: \(minute), Second: \(second)")
        print("Binary Encoded: [Year: \(yearBinary), Month: \(monthBinary), Day: \(dayBinary), Hour: \(hourBinary), Minute: \(minuteBinary), Second: \(secondBinary)]")

        // Use an invalid weekday for testing (optional)
        // Adjust weekday to match the diffuser's convention (Monday = 1, ..., Sunday = 7)
        let adjustedWeekday = (weekday == 1) ? 7 : UInt8(weekday - 1)

        // Construct the command
        let command: [UInt8] = [0x21, adjustedWeekday, yearBinary, monthBinary, dayBinary, hourBinary, minuteBinary, secondBinary]

        // Write to characteristic
        connectedPeripheral?.writeValue(Data(command), for: characteristic, type: .withResponse)

        // Log the sent command for debugging
        print("Sending time command: \(command.map { String(format: "%02x", $0) }.joined(separator: " "))")
    }


    private func setupReadyToSubscribePublisher() {
        Publishers.CombineLatest($state, $connectedPeripheral)
            .map { state, connectedPeripheral in
                state == .poweredOn && connectedPeripheral != nil
            }
            .sink { [weak self] isReady in
                self?.readyToSubscribe = isReady
                print("readyToSubscribe updated: \(isReady)")
            }
            .store(in: &cancellables)
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        switch state {
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

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber)
    {
        let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        print("Discovered device: \(deviceName ?? "Unnamed")")
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?)
    {
        print("Disconnected from \(peripheral.name ?? "Unknown")")
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?)
    {
        print("Failed to connect to \(peripheral.name ?? "Unknown")")
    }
}


struct AuthenticationResponse {
    let version: String
    let code: String?

    init?(data: Data) {
        // Ensure the data is valid and long enough
        guard data.count > 1, let rawVersionString = String(data: data[1...], encoding: .ascii) else {
            //print("Invalid Authentication Data: \(data.map { String(format: "0x%02x", $0) }.joined())")
            return nil
        }

        //print("Raw Version String: \(rawVersionString)")

        // Sanitize by removing control characters and trimming whitespace
        let sanitizedVersion = rawVersionString
            .components(separatedBy: .controlCharacters)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate that the sanitized string is ASCII-encodable
        guard sanitizedVersion.data(using: .ascii) != nil else {
            //print("Sanitized version string is not ASCII encodable: \(sanitizedVersion)")
            return nil
        }

        // Split into version and optional code
        let components = sanitizedVersion.split(separator: "T", maxSplits: 1, omittingEmptySubsequences: true)
        self.version = String(components.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.code = components.count > 1 ? String(components.last!).trimmingCharacters(in: .whitespacesAndNewlines) : nil

        //print("Parsed Version: \(self.version), Code: \(self.code ?? "None")")
    }
}

struct DataPacketResponse {
    let packetCount: Int
    let additionalData: Data?

    init?(data: Data) {
        guard data.count >= 2 else { return nil }
        self.packetCount = Int(data[1])
        self.additionalData = data.count > 2 ? data.subdata(in: 2..<data.count) : nil
    }
}

struct EquipmentVersionResponse {
    let version: String

    init?(data: Data) {
        guard let versionString = String(data: data[1...], encoding: .ascii) else { return nil }
        self.version = versionString
    }
}

struct GradeLimitsResponse {
    let maxGrade: UInt8
    let minCustomGradeWorking: UInt16
    let maxCustomGradeWorking: UInt16
    let minCustomGradePause: UInt16
    let maxCustomGradePause: UInt16
    let numberOfFragrances: UInt8
    let numberOfLightModes: UInt8

    init?(data: Data) {
        guard data.count >= 12 else { return nil }
        self.maxGrade = data[1]
        self.minCustomGradeWorking = UInt16(data[2]) << 8 | UInt16(data[3])
        self.maxCustomGradeWorking = UInt16(data[4]) << 8 | UInt16(data[5])
        self.minCustomGradePause = UInt16(data[6]) << 8 | UInt16(data[7])
        self.maxCustomGradePause = UInt16(data[8]) << 8 | UInt16(data[9])
        self.numberOfFragrances = data[10]
        self.numberOfLightModes = data[11]
    }
}

struct MachineModelResponse {
    let model: String

    init?(data: Data) {
        guard let modelString = String(data: data[1...], encoding: .ascii) else { return nil }
        self.model = modelString.trimmingCharacters(in: .controlCharacters)
    }
}

struct FragranceTimingResponse {
    var peripheralUUID = "UnknownUUID"
    let fragranceType: UInt8
    let atomizationSwitch: Bool
    let fanSwitch: Bool
    let currentTiming: UInt8
    let timingNumber: UInt8
    let powerOnTime: String
    let powerOffTime: String
    let daysOfOperation: [String]
    let gradeMode: String
    let grade: UInt8
    let customWorkTime: UInt16
    let customPauseTime: UInt16

    init?(data: Data) {
        guard data.count >= 18 else { return nil }
        // peripheralUUID is never set here!
        
        self.fragranceType = data[1]
        let switches = data[3]
        self.atomizationSwitch = (switches & 0x01) != 0
        self.fanSwitch = (switches & 0x02) != 0
        self.currentTiming = data[4]
        self.timingNumber = data[5]
        self.powerOnTime = String(format: "%02d:%02d", data[7], data[8])
        self.powerOffTime = String(format: "%02d:%02d", data[9], data[10])
        self.daysOfOperation = FragranceTimingResponse.decodeDaysOfWeek(byte: data[11])
        self.gradeMode = data[12] == 1 ? "Custom" : "Default"
        self.grade = data[13]
        self.customWorkTime = UInt16(data[14]) << 8 | UInt16(data[15])
        self.customPauseTime = UInt16(data[16]) << 8 | UInt16(data[17])

    }

    private static func decodeDaysOfWeek(byte: UInt8) -> [String] {
        let days = [
            (byte & 0x01) != 0 ? "Sunday" : nil,
            (byte & 0x02) != 0 ? "Monday" : nil,
            (byte & 0x04) != 0 ? "Tuesday" : nil,
            (byte & 0x08) != 0 ? "Wednesday" : nil,
            (byte & 0x10) != 0 ? "Thursday" : nil,
            (byte & 0x20) != 0 ? "Friday" : nil,
            (byte & 0x40) != 0 ? "Saturday" : nil
        ]
        return days.compactMap { $0 }
    }
}

struct GradeTimingResponse {
    let gradeTimings: [(workTime: UInt16, pauseTime: UInt16)]

    init?(data: Data) {
        guard data.count >= 82 else { return nil }
        var timings: [(UInt16, UInt16)] = []
        let gradeCount = 10

        for gradeIndex in 0..<gradeCount {
            let workTimeIndex = 1 + (gradeIndex * 4)
            let pauseTimeIndex = workTimeIndex + 2

            guard pauseTimeIndex + 1 < data.count else { return nil }

            let workTime = UInt16(data[workTimeIndex]) << 8 | UInt16(data[workTimeIndex + 1])
            let pauseTime = UInt16(data[pauseTimeIndex]) << 8 | UInt16(data[pauseTimeIndex + 1])
            timings.append((workTime, pauseTime))
        }
        self.gradeTimings = timings
    }
}

struct FragranceNamesResponse {
    let fragranceNames: [String]

    init?(data: Data) {
        guard data.count >= 65 else { return nil }
        var names: [String] = []

        for i in 0..<4 {
            let startIndex = 1 + (i * 16)
            let endIndex = startIndex + 16
            guard endIndex <= data.count else { return nil }
            let range = startIndex..<endIndex
            if let name = String(data: data[range], encoding: .ascii)?.trimmingCharacters(in: .controlCharacters), !name.isEmpty {
                names.append(name)
            }
        }
        self.fragranceNames = names
    }
}

struct EssentialOilStatusResponse {
    let batteryLevel: UInt8
    let essentialOilData: [(total: UInt16, remaining: UInt16)]

    init?(data: Data) {
        guard data.count >= 18 else { return nil }
        self.batteryLevel = data[1]
        var oilData: [(UInt16, UInt16)] = []

        for scentIndex in 0..<4 {
            let totalAmountIndex = 2 + (scentIndex * 4)
            let remainingAmountIndex = totalAmountIndex + 2

            guard remainingAmountIndex + 1 < data.count else { break }

            let totalAmount = UInt16(data[totalAmountIndex]) << 8 | UInt16(data[totalAmountIndex + 1])
            let remainingAmount = UInt16(data[remainingAmountIndex]) << 8 | UInt16(data[remainingAmountIndex + 1])
            oilData.append((totalAmount, remainingAmount))
        }
        self.essentialOilData = oilData
    }
}

struct ClockResponse {
    let currentTime: String
    let weekday: String

    init?(data: Data) {
        guard data.count >= 8 else { return nil }
        let weekdayIndex = data[1]
        let year = 2000 + Int(data[2])
        let month = data[3]
        let day = data[4]
        let hour = data[5]
        let minute = data[6]
        let second = data[7]

        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard weekdayIndex < weekdays.count else { return nil }
        self.weekday = weekdays[Int(weekdayIndex)]
        self.currentTime = String(format: "%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second)
    }
}

struct MainSwitchResponse {
    let mainSwitch: Bool
    let fanStatus: Bool
    let demoMode: Bool
    let atmosphereLightSwitch: Bool
    let atmosphereLightValue: UInt8

    init?(data: Data) {
        guard data.count >= 3 else { return nil }
        let mainSwitchByte = data[1]
        self.atmosphereLightValue = data[2]

        self.mainSwitch = (mainSwitchByte & 0x01) != 0
        self.fanStatus = (mainSwitchByte & 0x02) != 0
        self.demoMode = (mainSwitchByte & 0x04) != 0
        self.atmosphereLightSwitch = (mainSwitchByte & 0x08) != 0
    }
}

struct PCBAndEquipmentVersionResponse {
    let pcbVersion: String
    let equipmentVersion: String

    init?(data: Data) {
        guard data.count >= 33 else { return nil }
        guard let pcbVersionString = String(data: data[1...16], encoding: .ascii)?.trimmingCharacters(in: .controlCharacters),
              let equipmentVersionString = String(data: data[17...32], encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) else {
            return nil
        }
        self.pcbVersion = pcbVersionString
        self.equipmentVersion = equipmentVersionString
    }
}














// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    
    
    
    
    func loadDiffuserSettings() {
            guard let peripheral = connectedPeripheral,
                  let characteristic = pairingCharacteristic else {
                print("Error: No connected peripheral or pairing characteristic available.")
                return
            }

            diffuserAPI?.loadDiffuserSettings(peripheral: peripheral, characteristic: characteristic)
        }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
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
    
    func subscribeToNotifications(for characteristic: CBCharacteristic) {
        guard let peripheral = connectedPeripheral else {
            print("No connected peripheral to subscribe to notifications.")
            return
        }

        if characteristic.properties.contains(.notify) {
            peripheral.setNotifyValue(true, for: characteristic)
            print("Subscribed to notifications for characteristic: \(characteristic.uuid.uuidString)")
        } else {
            print("Characteristic \(characteristic.uuid.uuidString) does not support notifications.")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("⚠️ Characteristic discovery failed for \(service.uuid.uuidString): \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            print("No characteristics found for service \(service.uuid.uuidString).")
            return
        }
        for characteristic in characteristics {
            print("🔎 Discovered characteristic: \(characteristic.uuid.uuidString) on service \(service.uuid.uuidString)")

            // If it’s the pairing characteristic (FFF6):
            if characteristic.uuid == CBUUID(string: "FFF6") {
                pairingCharacteristic = characteristic
                print("🚪 Pairing characteristic found on \(peripheral.name ?? "Unknown").")
                
                // Subscribe to notifications for the pairing characteristic
                subscribeToNotifications(for: characteristic)
                
                // Attempt pairing by sending the password
                sendPairingPassword(peripheral: peripheral, customCode: "1234")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.sendCurrentTimeToDiffuserAsBinary()
                }
            }

            // If characteristic matches handle 0x000a (custom UUID):
            if characteristic.uuid == CBUUID(string: "000a") {
                subscribeToNotifications(for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else {
            print("Error receiving notification: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        let hexValue = value.map { String(format: "%02x", $0) }.joined()
        print("Received notification from \(characteristic.uuid): \(hexValue)")

        // Process notification data based on characteristic
        if characteristic.uuid == CBUUID(string: "000a") { // Match handle
            switch value[0] {
            case 0x40:
                print("Acknowledgment received: \(hexValue)")
                ackTimer?.invalidate()
                ackTimer = nil
                ackCompletion?(true)
                ackCompletion = nil
            case 0x46:
                print("Configuration data: \(hexValue)")
                // Process configuration data here
            case 0x42:
                if let model = String(data: value[1...], encoding: .ascii) {
                    print("Device Model and Serial: \(model)")
                    diffuserAPI?.saveDeviceModel(peripheralUUID: model, model: peripheral.identifier.uuidString)
                }
            default:
                print("Unhandled notification: \(hexValue)")
            }
        } else {
            parseResponse(value)
        }
    }

    /// Example function to check if the ACK data matches a success pattern
    private func isAckSuccess(_ data: Data) -> Bool {
        // e.g., you might expect `[0x1B, 0x02, 0x05, 0x00, 0x40, 0x11]`
        // so let's drop the first byte (the opcode) and compare the rest
        let expected: [UInt8] = [0x02, 0x05, 0x00, 0x40, 0x11]
        guard data.count >= 6 else { return false }
        let suffix = data.suffix(from: 1) // skip opcode
        return Array(suffix) == expected
    }

    /// Called when the correct ACK is confirmed
    private func notifyAckReceived() {
        // If your logic is storing a completion handler for the write:
        // e.g., ackCompletion?(.success(())) or ackCompletion?(.failure(...))
        // For demonstration, let's just log
        print("ACK received and validated!")
    }
    
    
    
    
}

extension BluetoothManager {

    /// Writes a sequence of bytes to a given characteristic using .withResponse.
    func writeCommand(_ command: [UInt8], to characteristic: CBCharacteristic) {
        let data = Data(command) // Convert [UInt8] to Data
        writeCommand(data, to: characteristic)
    }

    /// Writes a Data object to a given characteristic using .withResponse.
    func writeCommand(_ command: Data, to characteristic: CBCharacteristic) {
        guard let peripheral = characteristic.service?.peripheral else {
            print("No peripheral found in characteristic's service context.")
            return
        }

        // Write the data using CoreBluetooth's .withResponse
        peripheral.writeValue(command, for: characteristic, type: .withResponse)

        // Log for debugging
        let hexString = command.map { String(format: "%02x", $0) }.joined(separator: " ")
        print("BluetoothManager: wrote command [\(hexString)] to \(characteristic.uuid)")
    }
}
