import CoreBluetooth
import Combine

//needs msvu complint
class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()
    // Published properties for real-time updates
    @Published var discoveredDevices: [CBPeripheral] = [] // List of discovered devices
    @Published var isScanning: Bool = false               // Scanning state
    @Published var showConnectionAlert: Bool = false      // Show connection alert
    @Published var connectionAlertMessage: String = ""    // Connection alert message
    @Published var pairingResultMessage: String? = nil
    @Published var state: CBManagerState = .unknown
    @Published var readyToSubscribe: Bool = false {
        didSet {
            print("readyToSubscribe updated: \(readyToSubscribe)")
        }
    }
    @Published var connectedPeripheral: CBPeripheral?
    
    // Combine publishers for parsed responses
    var authenticationResponsePublisher = PassthroughSubject<AuthenticationResponse, Never>()
    var equipmentVersionPublisher = PassthroughSubject<EquipmentVersionResponse, Never>()
    var gradeLimitsPublisher = PassthroughSubject<GradeLimitsResponse, Never>()
    var machineModelPublisher = PassthroughSubject<MachineModelResponse, Never>()
    var fragranceTimingPublisher = PassthroughSubject<FragranceTimingResponse, Never>()
    var gradeTimingPublisher = PassthroughSubject<GradeTimingResponse, Never>()
    var fragranceNamesPublisher = PassthroughSubject<FragranceNamesResponse, Never>()
    var essentialOilStatusPublisher = PassthroughSubject<EssentialOilStatusResponse, Never>()
    var clockResponsePublisher = PassthroughSubject<ClockResponse, Never>()
    var mainSwitchPublisher = PassthroughSubject<MainSwitchResponse, Never>()
    var pcbAndEquipmentVersionPublisher = PassthroughSubject<PCBAndEquipmentVersionResponse, Never>()
    var genericResponsePublisher = PassthroughSubject<Data, Never>()
    
    private var cancellables: Set<AnyCancellable> = []
    private var centralManager: CBCentralManager!

    private var pairingCharacteristic: CBCharacteristic?
    private var responseHandlers: [UInt8: (Data) -> Void] = [:]
    private var validStartBytes: Set<UInt8> = [
        0x8f, 0x0f, 0x40, 0x41, 0x21, 0x81, 0x01, 0x42, 0x22, 0xC2, 0xA2,
        0x85, 0x05, 0x43, 0xC3, 0x23, 0xA3, 0x86, 0x87, 0x44, 0xC4, 0x45,
        0xC5, 0x84, 0x46, 0xC6, 0x47, 0xC7, 0x03, 0x83, 0x4a, 0x48, 0xC8,
        0x4b, 0xcb, 0x41, 0x21, 0x4D
    ]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        state = centralManager.state
        setupResponseHandlers()
        setupReadyToSubscribePublisher()
        print("BluetoothManager initialized: \(Unmanaged.passUnretained(self).toOpaque())")
        

        // Add Combine subscription for authentication responses
        authenticationResponsePublisher
            .sink { response in
                print("Published authentication response: \(response.version)")
                if response.version.hasPrefix("CY_V3") {
                    print("Authentication successful with version \(response.version)")
                    // Trigger additional actions, e.g., request data from the device
                    if let peripheral = self.connectedPeripheral {
                        self.requestDataFromDevice(peripheral: peripheral)
                        
                       
                    }
                } else {
                    print("Unexpected authentication version: \(response.version)")
                }
            }
            .store(in: &cancellables)
    }
    
    
    private func setupReadyToSubscribePublisher() {
        Publishers.CombineLatest($state, $connectedPeripheral)
            .map { state, connectedPeripheral in
                return state == .poweredOn && connectedPeripheral != nil
            }
            .sink { [weak self] isReady in
                self?.readyToSubscribe = isReady
                print("readyToSubscribe updated via Combine: \(isReady)")
            }
            .store(in: &cancellables)
        print("setup Ready To Subscribe Publisher executed")
    }
    
    private func setupResponseHandlers() {
        responseHandlers = [
            0x8f: parseAuthenticationResponse,
            0x40: parseDataPacketResponse,
            0x87: parseEquipmentVersionResponse,
            0x46: parseGradeLimitsResponse,
            0x45: parseMachineModelResponse,
            0x4a: parseFragranceTimingResponse,
            0x47: parseGradeTimingResponse,
            0xC7: parseGradeTimingResponse,
            0x48: parseFragranceNamesResponse,
            0x4b: parseEssentialOilStatusResponse,
            0xcb: parseEssentialOilStatusResponse,
            0xC1: parseClockResponse,
            0x41: parseClockResponse,
            0x4D: parseMainSwitchResponse,
            0x44: parsePCBAndEquipmentVersionResponse,
            // Add other mappings as needed
        ]
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
        centralManager.scanForPeripherals(withServices: [CBUUID(string: "FFF0")], options: nil)
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
    
    func simulateAuthenticationResponse() {
        // Create mock data that represents the expected input format

        
        let realData = Data([0x8f, 0x43, 0x59, 0x5f, 0x56, 0x33, 0x2e, 0x30, 0x41, 0x41, 0x30, 0x31, 0x54])
        
        let mockVersionString = "CY_V3.0AA01T@"
        guard let mockData = mockVersionString.data(using: .ascii) else {
            print("Failed to create mock Data for AuthenticationResponse")
            return
        }
        
        // Prepend the required byte if needed (depends on your AuthenticationResponse logic)
        let mockResponseData = Data([0x8F]) + realData

        // Initialize AuthenticationResponse with the mock data
        if let mockResponse = AuthenticationResponse(data: mockResponseData) {
            print("Publishing mock authentication response: \(mockResponse.version)")
            authenticationResponsePublisher.send(mockResponse)
        } else {
            print("Failed to create mock AuthenticationResponse")
        }
    }
    
    /// Send pairing password to the device
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

    /// Request equipment version from the device
    func requestEquipmentVersion(peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Characteristic not found.")
            return
        }

        let command = Data([0x87]) // Command to request equipment version
        peripheral.writeValue(command, for: characteristic, type: .withResponse)
        print("Sent 0x87 command to request equipment version.")
    }

    /// Request data from the device
    func requestDataFromDevice(peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Characteristic not found.")
            return
        }
        let command = Data([0x40]) // Command to request data packets
        peripheral.writeValue(command, for: characteristic, type: .withResponse)
        print("Sent 0x40 command to request data packets.")
    }

    /// Send old protocol password
    func sendOldProtocolPassword(password: String, peripheral: CBPeripheral) {
        guard let characteristic = pairingCharacteristic else {
            print("Pairing characteristic not found.")
            return
        }
        let command = createOldProtocolCommand(password: password)
        peripheral.writeValue(command, for: characteristic, type: .withResponse)
        print("Old protocol password sent.")
    }

    /// Send new protocol password
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
                    // self.requestDataFromDevice(peripheral: peripheral)
                    // self.requestEquipmentVersion(peripheral: peripheral)
                } else {
                    print("Pairing failed: \(self.pairingResultMessage ?? "Unknown error").")
                }
            }
        }
    }

    /// Handle incoming data packets
    func handleIncomingDataPackets(peripheral: CBPeripheral, characteristic: CBCharacteristic, packetCount: Int) {
        var receivedPackets: [Data] = []
        var timeoutTimer: Timer? // Declare a variable to hold the timer

        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            if receivedPackets.count < packetCount {
                print("Timeout waiting for all packets. Received \(receivedPackets.count)/\(packetCount).")
                // Handle incomplete data here
            }
        }

        func onPacketReceived(data: Data) {
            receivedPackets.append(data)
            print("Received packet \(receivedPackets.count)/\(packetCount).")

            if receivedPackets.count == packetCount {
                print("All packets received.")
                timeoutTimer?.invalidate() // Invalidate the timer once all packets are received
                processReceivedData(receivedPackets)
            }
        }

        // Process the first packet if available
        if let data = characteristic.value {
            onPacketReceived(data: data)
        }
    }

    /// Parse combined data from multiple packets
    func processReceivedData(_ packets: [Data]) {
        // Combine packets
        let combinedData = packets.reduce(Data()) { $0 + $1 }
        print("Combined Data: \(combinedData.map { String(format: "%02x", $0) }.joined())")

        // Further processing
        parseCombinedData(combinedData)
    }

    /// Parse the response data
    func parseResponse(_ data: Data) {
        guard let startByte = data.first else {
            print("Invalid response: Data too short.")
            return
        }

        print("Received data: \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
        print("Received start byte: 0x\(String(format: "%02x", startByte))")

        if let handler = responseHandlers[startByte] {
            handler(data)
        } else {
            print("Unhandled Response Type (Start Byte: 0x\(String(format: "%02x", startByte)))")
        }
    }

    /// Create old protocol command
    private func createOldProtocolCommand(password: String) -> Data {
        var commandData = Data([0x8F])
        if let passwordData = password.data(using: .ascii) {
            commandData.append(passwordData)
        }
        return commandData
    }

    /// Create new protocol command
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

// MARK: - Helper Functions and Extensions

extension BluetoothManager {
    /// Helper function to extract UInt16 from data at a given index
    func extractUInt16(from data: Data, at index: Int) -> UInt16? {
        guard index + 1 < data.count else { return nil }
        return UInt16(data[index]) << 8 | UInt16(data[index + 1])
    }

    /// Helper function to extract String from data in a given range
    func extractString(from data: Data, range: Range<Int>) -> String? {
        guard range.lowerBound >= 0, range.upperBound <= data.count else { return nil }
        let subData = data.subdata(in: range)
        return String(data: subData, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters)
    }

    /// Parse combined data from multiple packets
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
}

// MARK: - Response Structs

struct AuthenticationResponse {
    let version: String
    let code: String?

    init?(data: Data) {
        // Ensure the data is valid and long enough
        guard data.count > 1, let rawVersionString = String(data: data[1...], encoding: .ascii) else {
            print("Invalid Authentication Data: \(data.map { String(format: "0x%02x", $0) }.joined())")
            return nil
        }

        print("Raw Version String: \(rawVersionString)")

        // Sanitize by removing control characters and trimming whitespace
        let sanitizedVersion = rawVersionString
            .components(separatedBy: .controlCharacters)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate that the sanitized string is ASCII-encodable
        guard sanitizedVersion.data(using: .ascii) != nil else {
            print("Sanitized version string is not ASCII encodable: \(sanitizedVersion)")
            return nil
        }

        // Split into version and optional code
        let components = sanitizedVersion.split(separator: "T", maxSplits: 1, omittingEmptySubsequences: true)
        self.version = String(components.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.code = components.count > 1 ? String(components.last!).trimmingCharacters(in: .whitespacesAndNewlines) : nil

        print("Parsed Version: \(self.version), Code: \(self.code ?? "None")")
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

// MARK: - Parsing Functions Using Structs

extension BluetoothManager {
    func parseAuthenticationResponse(_ data: Data) {
        print("Parsing Authentication Response...")
        if let response = AuthenticationResponse(data: data) {
            print("Parsed Authentication Response: \(response.version)")
            DispatchQueue.main.async {
                self.authenticationResponsePublisher.send(response)
            }

            // Trigger logic based on the response
            if response.version.hasPrefix("CY_V3") {
                print("Authentication successful with version \(response.version)")
                // Handle successful authentication logic here
            } else {
                print("Unexpected authentication response: \(response.version)")
            }
        } else {
            print("Failed to parse authentication response.")
        }
    }

    func parseDataPacketResponse(_ data: Data) {
        if let response = DataPacketResponse(data: data) {
            print("Data Packet Response:")
            print("Packet Count: \(response.packetCount)")

            // Safely unwrap connectedPeripheral and pairingCharacteristic
            guard let peripheral = connectedPeripheral,
                  let characteristic = pairingCharacteristic else {
                print("Error: connectedPeripheral or pairingCharacteristic is nil.")
                return
            }

            // Pass the unwrapped values to the method
            handleIncomingDataPackets(peripheral: peripheral, characteristic: characteristic, packetCount: response.packetCount)
        } else {
            print("Failed to parse data packet response.")
        }
    }

    func parseEquipmentVersionResponse(_ data: Data) {
        if let response = EquipmentVersionResponse(data: data) {
            print("Equipment Version: \(response.version)")
            equipmentVersionPublisher.send(response)
        } else {
            print("Failed to parse equipment version response.")
        }
    }


    func parseGradeLimitsResponse(_ data: Data) {
        if let response = GradeLimitsResponse(data: data) {
            print("Grade Limits Response:")
            print("Max Grade: \(response.maxGrade)")
            print("Min Custom Grade Working: \(response.minCustomGradeWorking)")
            print("Max Custom Grade Working: \(response.maxCustomGradeWorking)")
            print("Min Custom Grade Pause: \(response.minCustomGradePause)")
            print("Max Custom Grade Pause: \(response.maxCustomGradePause)")
            print("Number of Fragrances: \(response.numberOfFragrances)")
            print("Number of Atmosphere Light Modes: \(response.numberOfLightModes)")
            gradeLimitsPublisher.send(response)
        } else {
            print("Failed to parse grade limits response.")
        }
    }

    func parseMachineModelResponse(_ data: Data) {
        if let response = MachineModelResponse(data: data) {
            print("Machine Model: \(response.model)")
            machineModelPublisher.send(response)
        } else {
            print("Failed to parse machine model response.")
        }
    }


    func parseFragranceTimingResponse(_ data: Data) {
        if let response = FragranceTimingResponse(data: data) {
            print("Fragrance Timing Response:")
            print("Fragrance Type: \(response.fragranceType)")
            print("Atomization Switch: \(response.atomizationSwitch ? "On" : "Off")")
            print("Fan Switch: \(response.fanSwitch ? "On" : "Off")")
            print("Current Timing Number: \(response.currentTiming)")
            print("Timing Number: \(response.timingNumber)")
            print("Power On: \(response.powerOnTime)")
            print("Power Off: \(response.powerOffTime)")
            print("Days of Operation: \(response.daysOfOperation.joined(separator: ", "))")
            print("Grade Mode: \(response.gradeMode)")
            print("Grade: \(response.grade)")
            print("Custom Work Time: \(response.customWorkTime) seconds")
            print("Custom Pause Time: \(response.customPauseTime) seconds")
            fragranceTimingPublisher.send(response)
        } else {
            print("Failed to parse fragrance timing response.")
        }
    }

    func parseGradeTimingResponse(_ data: Data) {
        if let response = GradeTimingResponse(data: data) {
            print("Grade Timing Response:")
            for (index, timing) in response.gradeTimings.enumerated() {
                print("Grade \(index + 1): Work Time = \(timing.workTime) seconds, Pause Time = \(timing.pauseTime) seconds")
            }
            gradeTimingPublisher.send(response)
        } else {
            print("Failed to parse grade timing response.")
        }
    }

    func parseFragranceNamesResponse(_ data: Data) {
        if let response = FragranceNamesResponse(data: data) {
            print("Fragrance Names Response:")
            for (index, name) in response.fragranceNames.enumerated() {
                print("Fragrance \(index + 1): \(name)")
            }
            fragranceNamesPublisher.send(response)
        } else {
            print("Failed to parse fragrance names response.")
        }
    }

    func parseEssentialOilStatusResponse(_ data: Data) {
        if let response = EssentialOilStatusResponse(data: data) {
            print("Essential Oil Status Response:")
            print("Battery Level: \(response.batteryLevel)%")
            for (index, oil) in response.essentialOilData.enumerated() {
                print("Scent \(index + 1): Total Amount = \(oil.total), Remaining Amount = \(oil.remaining)")
            }
            essentialOilStatusPublisher.send(response)
        } else {
            print("Failed to parse essential oil status response.")
        }
    }

    func parseClockResponse(_ data: Data) {
        if let response = ClockResponse(data: data) {
            print("Clock Response:")
            print("Current Time: \(response.currentTime)")
            print("Weekday: \(response.weekday)")
            clockResponsePublisher.send(response)
        } else {
            print("Failed to parse clock response.")
        }
    }

    func parseMainSwitchResponse(_ data: Data) {
        if let response = MainSwitchResponse(data: data) {
            print("Main Switch Response:")
            print("Main Switch: \(response.mainSwitch ? "On" : "Off")")
            print("Fan Status: \(response.fanStatus ? "On (Fixed)" : "Off")")
            print("Demo Mode: \(response.demoMode ? "Enabled" : "Disabled")")
            print("Atmosphere Light Switch: \(response.atmosphereLightSwitch ? "On (Fixed)" : "Off")")
            print("Atmosphere Light Value: \(response.atmosphereLightValue)")
            mainSwitchPublisher.send(response)
        } else {
            print("Failed to parse main switch response.")
        }
    }

    func parsePCBAndEquipmentVersionResponse(_ data: Data) {
        if let response = PCBAndEquipmentVersionResponse(data: data) {
            print("PCB and Equipment Version Response:")
            print("PCB Version: \(response.pcbVersion)")
            print("Equipment Version: \(response.equipmentVersion)")
            pcbAndEquipmentVersionPublisher.send(response)
        } else {
            print("Failed to parse PCB and equipment version response.")
        }
    }

    func parseGenericResponse(_ data: Data) {
        let asciiPart = data[1...]
        if let decodedString = String(data: asciiPart, encoding: .ascii) {
            print("Generic ASCII Data: \(decodedString)")
        } else {
            print("Raw Data: \(data.map { String(format: "0x%02x", $0) }.joined(separator: " "))")
        }
        genericResponsePublisher.send(data)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    // Update Bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
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
        setupReadyToSubscribePublisher()
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

            if characteristic.uuid == CBUUID(string: "FFF6") {
                pairingCharacteristic = characteristic
                print("Pairing characteristic found.")

                // Automatically send pairing password when characteristic is found
                let customCode = "1234" // Replace with actual custom code if needed
                sendPairingPassword(peripheral: peripheral, customCode: customCode)

                // Optionally subscribe to notifications
                if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    // Handle updates to characteristic values
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading value: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            print("No data received.")
            return
        }

        print("Raw Data Received: \(data.map { String(format: "0x%02x", $0) }.joined())")
        print("ASCII Representation: \(String(data: data, encoding: .ascii) ?? "Invalid ASCII Data")")

        parseResponse(data)
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

