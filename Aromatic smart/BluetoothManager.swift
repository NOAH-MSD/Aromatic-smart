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
    private var pairingCharacteristic: CBCharacteristic?

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

    func connect(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        peripheral.delegate = self
        print("Connecting to \(peripheral.name ?? "Unknown")...")
    }

    func parseResponse(_ data: Data) {
        diffuserAPI?.parseResponse(data)
    }

    /// Example: Expose a method to request equipment version
    func requestEquipmentVersion(peripheral: CBPeripheral) {
        diffuserAPI?.requestEquipmentVersion(peripheral: peripheral,
                                             characteristic: pairingCharacteristic)
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

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
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

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?)
    {
        if let error = error {
            print("Failed to discover characteristics: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid.uuidString)")
            // For typeA, maybe it's FFF6
            if characteristic.uuid == CBUUID(string: "FFF6") {
                pairingCharacteristic = characteristic
                print("Pairing characteristic found.")
                // Possibly send pairing here...
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        if let error = error {
            print("Error reading value: \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else {
            print("No data received.")
            return
        }
        parseResponse(data)
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
