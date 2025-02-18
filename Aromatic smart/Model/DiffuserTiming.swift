import SwiftData
import Foundation

@Model
class Timing: Identifiable {
    var id: UUID = UUID()

    // Example properties
    var number: Int
    var powerOn: String
    var powerOff: String
    var daysOfOperation: [String]
    var gradeMode: Bool
    var grade: Int
    var customWorkTime: Int
    var customPauseTime: Int

    // Add this to fix "Value of type 'Timing' has no member 'fanSwitch'"
    var fanSwitch: Bool = false

    init(
        number: Int,
        powerOn: String,
        powerOff: String,
        daysOfOperation: [String],
        gradeMode: Bool = false,
        grade: Int,
        customWorkTime: Int,
        customPauseTime: Int,
        fanSwitch: Bool = false
    ) {
        self.number = number
        self.powerOn = powerOn
        self.powerOff = powerOff
        self.daysOfOperation = daysOfOperation
        self.gradeMode = gradeMode
        self.grade = grade
        self.customWorkTime = customWorkTime
        self.customPauseTime = customPauseTime
        self.fanSwitch = fanSwitch
    }
}
