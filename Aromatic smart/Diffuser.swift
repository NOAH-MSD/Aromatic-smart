import Foundation
import SwiftData
import CoreBluetooth

@Model
class Diffuser: Identifiable {
    // MARK: - Core Properties
    var id = UUID()
    var name: String
    var isConnected: Bool
    var modelNumber: String
    var serialNumber: String
    var timerSetting: Int

    // MARK: - Transformable Array Properties with Transformer
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData"))
    private var daysOfOperationStorage: [String]?

    @Attribute(.transformable(by: "NSSecureUnarchiveFromData"))
    private var supportedFeaturesStorage: [String]?

    @Attribute(.transformable(by: "NSSecureUnarchiveFromData"))
    private var customCommandsStorage: [String]?

    @Attribute(.transformable(by: "NSSecureUnarchiveFromData"))
    private var fragranceNamesStorage: [String]?

    // MARK: - Computed Properties for Array Access
    var daysOfOperation: [String] {
        get { daysOfOperationStorage ?? [] }
        set { daysOfOperationStorage = newValue }
    }

    var supportedFeatures: [String] {
        get { supportedFeaturesStorage ?? [] }
        set { supportedFeaturesStorage = newValue }
    }

    var customCommands: [String] {
        get { customCommandsStorage ?? [] }
        set { customCommandsStorage = newValue }
    }

    var fragranceNames: [String] {
        get { fragranceNamesStorage ?? [] }
        set { fragranceNamesStorage = newValue }
    }

    // MARK: - Bluetooth-Specific Properties
    var peripheralUUID: String? // Persist the UUID of the peripheral
    @Transient var peripheral: CBPeripheral? // Runtime-only reference for Bluetooth operations

    // Bluetooth-related data
    var rssi: Int?
    var lastSeen: Date?

    // MARK: - Diffuser State
    var powerOn: String = ""
    var powerOff: String = ""
    var gradeMode: String = ""
    var grade: Int = 0
    var customWorkTime: Int = 0
    var customPauseTime: Int = 0
    var mainSwitch: Bool = false
    var fanStatus: Bool = false
    var clockTime: Date? = nil

    // Device status
    var status: String = "Idle"
    var isUpdating: Bool = false

    // MARK: - Metadata
    var firmwareVersion: String = ""
    var hardwareVersion: String = ""

    // MARK: - User Preferences with Transformer
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData"))
    private var userPreferencesStorage: [UserPreference]?

    var userPreferences: [UserPreference] {
        get { userPreferencesStorage ?? [] }
        set { userPreferencesStorage = newValue }
    }

    struct UserPreference: Codable {
        var preferenceKey: String
        var preferenceValue: String
    }

    // MARK: - Initializer
    init(name: String, isConnected: Bool, modelNumber: String, serialNumber: String, timerSetting: Int) {
        self.name = name
        self.isConnected = isConnected
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.timerSetting = timerSetting
    }

    // MARK: - Helper Methods
    /// Link a Bluetooth peripheral to this diffuser and store its UUID.
    func linkPeripheral(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheralUUID = peripheral.identifier.uuidString
    }

    /// Update diffuser state properties based on received data.
    func updateState(powerOn: String, powerOff: String, gradeMode: String, grade: Int, workTime: Int, pauseTime: Int, mainSwitch: Bool, fanStatus: Bool) {
        self.powerOn = powerOn
        self.powerOff = powerOff
        self.gradeMode = gradeMode
        self.grade = grade
        self.customWorkTime = workTime
        self.customPauseTime = pauseTime
        self.mainSwitch = mainSwitch
        self.fanStatus = fanStatus
    }

    /// Add a user preference to the preferences list.
    func addUserPreference(key: String, value: String) {
        var preferences = userPreferences
        let preference = UserPreference(preferenceKey: key, preferenceValue: value)
        preferences.append(preference)
        userPreferences = preferences
    }

    /// Remove a user preference by key.
    func removeUserPreference(for key: String) {
        userPreferences.removeAll { $0.preferenceKey == key }
    }
}
