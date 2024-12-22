import SwiftData
import Foundation

@Model
class Diffuser: Identifiable {
    // Core properties
    var id: UUID = UUID()
    var name: String
    var isConnected: Bool
    var modelNumber: String
    var serialNumber: String
    var timerSetting: Int
    var peripheralUUID: String?
    
    // Re-add these fields if they belong to the entire diffuser
    var mainSwitch: Bool = false
    var fanStatus: Bool = false
    var clockTime: Date?

    // Relationship to multiple Timings, if you have that
    @Relationship var timings: [Timing] = []

    // Additional diffuser-specific properties
    var status: String = "Idle"
    var firmwareVersion: String = ""
    var hardwareVersion: String = ""
    // ... any other fields that are truly about the diffuser itself ...

    // Example initializer
    init(
        name: String,
        isConnected: Bool,
        modelNumber: String,
        serialNumber: String,
        timerSetting: Int,
        peripheralUUID: String? = nil
    ) {
        self.name = name
        self.isConnected = isConnected
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.timerSetting = timerSetting
        self.peripheralUUID = peripheralUUID
    }
    
    // Example methods
    func updateDiffuserStatus(isConnected: Bool, newStatus: String) {
        self.isConnected = isConnected
        self.status = newStatus
    }
}
