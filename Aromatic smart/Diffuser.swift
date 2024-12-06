import Foundation
import SwiftData
import CoreBluetooth

@Model
class Diffuser: Identifiable {
    // MARK: Core Properties
    var id = UUID()
    var name: String
    var isConnected: Bool
    var modelNumber: String
    var serialNumber: String
    var timerSetting: Int

    // MARK: - transformable Properties using Codable Types
    var daysOfOperationWrapper: StringArrayWrapper?
    var supportedFeaturesWrapper: StringArrayWrapper?
    var customCommandsWrapper: StringArrayWrapper?
    var fragranceNamesWrapper: StringArrayWrapper?

    // MARK: - Computed Properties for Array Access
    var daysOfOperation: [String] {
        get { daysOfOperationWrapper?.values ?? [] }
        set { daysOfOperationWrapper = StringArrayWrapper(values: newValue) }
    }

    var supportedFeatures: [String] {
        get { supportedFeaturesWrapper?.values ?? [] }
        set { supportedFeaturesWrapper = StringArrayWrapper(values: newValue) }
    }

    var customCommands: [String] {
        get { customCommandsWrapper?.values ?? [] }
        set { customCommandsWrapper = StringArrayWrapper(values: newValue) }
    }

    var fragranceNames: [String] {
        get { fragranceNamesWrapper?.values ?? [] }
        set { fragranceNamesWrapper = StringArrayWrapper(values: newValue) }
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
    var clockTime: Date?

    // Device status
    var status: String = "Idle"
    var isUpdating: Bool = false

    // MARK: - Metadata
    var firmwareVersion: String = ""
    var hardwareVersion: String = ""

    // MARK: - User Preferences
    var userPreferencesWrapper: UserPreferencesWrapper?

    var userPreferences: [UserPreference] {
        get { userPreferencesWrapper?.preferences ?? [] }
        set { userPreferencesWrapper = UserPreferencesWrapper(preferences: newValue) }
    }

    struct UserPreference: Codable {
        var preferenceKey: String
        var preferenceValue: String
    }

    struct UserPreferencesWrapper: Codable {
        var preferences: [UserPreference]
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

struct StringArrayWrapper: Codable {
    var values: [String]
}
