import Foundation
import SwiftData


@Model
class Diffuser: ObservableObject, Identifiable {
    // MARK: Core Properties
    var peripheralUUID: String? // Persist the UUID of the peripheral
    var id = UUID()
    var name: String
    var isConnected: Bool
    var modelNumber: String
    var serialNumber: String
    var timerSetting: Int

    // Properties for fragrance timing
    var atomizationSwitch: Bool = false
    var fanSwitch: Bool = false
    var currentTiming: Int = 0
    var timingNumber: Int = 0
    var powerOn: String = "00:00"
    var powerOff: String = "00:00"
    var gradeMode: String = "Default"
    var grade: Int = 0
    var customWorkTime: Int = 0
    var customPauseTime: Int = 0

    // MARK: - Transformable Properties using Codable Types
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

    //@Transient var peripheral: CBPeripheral? // Runtime-only reference for Bluetooth operations
    //TODO chick this out later
    
    // Bluetooth-related data
    var rssi: Int?
    var lastSeen: Date?

    // MARK: - Diffuser State
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
    init(name: String,
         isConnected: Bool,
         modelNumber: String,
         serialNumber: String,
         timerSetting: Int,
         peripheralUUID: String? = nil) {
        self.name = name
        self.isConnected = isConnected
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.timerSetting = timerSetting
        self.peripheralUUID = peripheralUUID
    }

    // MARK: - Helper Methods


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
