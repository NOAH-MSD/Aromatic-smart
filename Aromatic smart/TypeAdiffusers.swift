import CoreBluetooth
import Combine

/// A protocol describing all the operations needed by a diffuser type.
/// For example, Type A or Type B.
protocol DiffuserAPI {
    /// Service UUIDs to scan for
    var scanServiceUUIDs: [CBUUID] { get }
    /// Byte command for requesting equipment version
    var requestEquipmentVersionByte: UInt8 { get }
    /// Valid start bytes recognized by this diffuser type
    var validStartBytes: Set<UInt8> { get }
    /// Response handlers mapped to each recognized start byte
    var responseHandlers: [UInt8: (Data) -> Void] { get }

    func startScanning(manager: CBCentralManager)
    func requestEquipmentVersion(peripheral: CBPeripheral, characteristic: CBCharacteristic?)
    func parseResponse(_ data: Data)
}

/// Type A diffuser logic: scanning, equipment version command, valid start bytes, parse handlers
class TypeADiffuserAPI: DiffuserAPI {
    // MARK: - Weak reference back to BluetoothManager
    /// We keep a weak var to avoid strong reference cycles.
    weak var bluetoothManager: BluetoothManager?

    // MARK: - DiffuserAPI protocol properties
    let scanServiceUUIDs: [CBUUID] = [CBUUID(string: "FFF0")]  // Type A scans for FFF0
    let requestEquipmentVersionByte: UInt8 = 0x87              // Type A uses 0x87
    let validStartBytes: Set<UInt8> = [
        0x8f, 0x0f, 0x40, 0x41, 0x21, 0x81, 0x01, 0x42, 0x22, 0xC2, 0xA2,
        0x85, 0x05, 0x43, 0xC3, 0x23, 0xA3, 0x86, 0x87, 0x44, 0xC4, 0x45,
        0xC5, 0x84, 0x46, 0xC6, 0x47, 0xC7, 0x03, 0x83, 0x4a, 0x48, 0xC8,
        0x4b, 0xcb, 0x4D
    ]

    /// Mapping of start bytes to parse functions
    lazy var responseHandlers: [UInt8: (Data) -> Void] = [
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
        0x41: parseClockResponse,
        0x4D: parseMainSwitchResponse,
        0x44: parsePCBAndEquipmentVersionResponse
    ]

    // MARK: - Init
    init(bluetoothManager: BluetoothManager?) {
        self.bluetoothManager = bluetoothManager
    }

    // MARK: - DiffuserAPI Protocol Methods

    /// Start scanning with Type A logic
    func startScanning(manager: CBCentralManager) {
        manager.scanForPeripherals(withServices: scanServiceUUIDs, options: nil)
        print("Type A scanning started. Service UUIDs: \(scanServiceUUIDs.map(\.uuidString).joined())")
    }

    /// Request equipment version (Type A uses a single byte `[0x87]`)
    func requestEquipmentVersion(peripheral: CBPeripheral, characteristic: CBCharacteristic?) {
        guard let c = characteristic else {
            print("Type A: No characteristic to request equipment version.")
            return
        }
        let command = Data([requestEquipmentVersionByte]) // 0x87
        peripheral.writeValue(command, for: c, type: .withResponse)
        print("Type A: Sent 0x\(String(format: "%02x", requestEquipmentVersionByte)) to request equipment version.")
    }

    /// Parse raw data using the recognized start bytes and mapped handlers
    func parseResponse(_ data: Data) {
        guard let startByte = data.first else {
            print("Type A parseResponse: Empty data.")
            return
        }
        guard validStartBytes.contains(startByte) else {
            print("Type A parseResponse: Unrecognized start byte 0x\(String(format: "%02x", startByte)).")
            return
        }
        if let handler = responseHandlers[startByte] {
            handler(data)
        } else {
            print("Type A parseResponse: No handler for byte 0x\(String(format: "%02x", startByte)).")
        }
    }

    // MARK: - Private Parse Handlers

    /// Example: parse authentication response for Type A
    private func parseAuthenticationResponse(_ data: Data) {
        print("Type A parseAuthenticationResponse: \(hexDump(data))")
        // Suppose we decode an AuthenticationResponse from data
        if let response = AuthenticationResponse(data: data) {
            // Publish to the bluetoothManager's authenticationResponsePublisher
            bluetoothManager?.authenticationResponsePublisher.send(response)
        } else {
            print("Type A: Failed to parse authentication response from data.")
        }
    }

    private func parseDataPacketResponse(_ data: Data) {
        print("Type A parseDataPacketResponse: \(hexDump(data))")
        // Possibly decode something, or call a publisher
    }

    private func parseEquipmentVersionResponse(_ data: Data) {
        print("Type A parseEquipmentVersionResponse: \(hexDump(data))")
        if let eqVersion = EquipmentVersionResponse(data: data) {
            bluetoothManager?.equipmentVersionPublisher.send(eqVersion)
        } else {
            print("Type A: Failed to parse equipment version.")
        }
    }

    private func parseGradeLimitsResponse(_ data: Data) {
        print("Type A parseGradeLimitsResponse: \(hexDump(data))")
        if let limits = GradeLimitsResponse(data: data) {
            bluetoothManager?.gradeLimitsPublisher.send(limits)
        }
    }

    private func parseMachineModelResponse(_ data: Data) {
        print("Type A parseMachineModelResponse: \(hexDump(data))")
        if let model = MachineModelResponse(data: data) {
            bluetoothManager?.machineModelPublisher.send(model)
        }
    }

    private func parseFragranceTimingResponse(_ data: Data) {
        print("Type A parseFragranceTimingResponse: \(hexDump(data))")
        if let ft = FragranceTimingResponse(data: data) {
            bluetoothManager?.fragranceTimingPublisher.send(ft)
        }
    }

    private func parseGradeTimingResponse(_ data: Data) {
        print("Type A parseGradeTimingResponse: \(hexDump(data))")
        if let gt = GradeTimingResponse(data: data) {
            bluetoothManager?.gradeTimingPublisher.send(gt)
        }
    }

    private func parseFragranceNamesResponse(_ data: Data) {
        print("Type A parseFragranceNamesResponse: \(hexDump(data))")
        if let fn = FragranceNamesResponse(data: data) {
            bluetoothManager?.fragranceNamesPublisher.send(fn)
        }
    }

    private func parseEssentialOilStatusResponse(_ data: Data) {
        print("Type A parseEssentialOilStatusResponse: \(hexDump(data))")
        if let eo = EssentialOilStatusResponse(data: data) {
            bluetoothManager?.essentialOilStatusPublisher.send(eo)
        }
    }

    private func parseClockResponse(_ data: Data) {
        print("Type A parseClockResponse: \(hexDump(data))")
        if let clock = ClockResponse(data: data) {
            bluetoothManager?.clockResponsePublisher.send(clock)
        }
    }

    private func parseMainSwitchResponse(_ data: Data) {
        print("Type A parseMainSwitchResponse: \(hexDump(data))")
        if let mainSwitch = MainSwitchResponse(data: data) {
            bluetoothManager?.mainSwitchPublisher.send(mainSwitch)
        }
    }

    private func parsePCBAndEquipmentVersionResponse(_ data: Data) {
        print("Type A parsePCBAndEquipmentVersionResponse: \(hexDump(data))")
        if let pcbv = PCBAndEquipmentVersionResponse(data: data) {
            bluetoothManager?.pcbAndEquipmentVersionPublisher.send(pcbv)
        }
    }

    // MARK: - Helper

    /// Convert Data to a hex string for logging
    private func hexDump(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}
