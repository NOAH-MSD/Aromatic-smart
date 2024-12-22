import SwiftData
import Foundation

@Model
class Timing: Identifiable {
    // Core properties
    var id: UUID = UUID()
    
    // Example fields (from your fragrance timing responses)
    var number: Int
    var powerOn: String
    var powerOff: String
    var daysOfOperation: [String] // or a transformable property if you prefer
    var gradeMode: String
    var grade: Int
    var customWorkTime: Int
    var customPauseTime: Int
    
    // Initializer
    init(
        number: Int,
        powerOn: String,
        powerOff: String,
        daysOfOperation: [String],
        gradeMode: String,
        grade: Int,
        customWorkTime: Int,
        customPauseTime: Int
    ) {
        self.number = number
        self.powerOn = powerOn
        self.powerOff = powerOff
        self.daysOfOperation = daysOfOperation
        self.gradeMode = gradeMode
        self.grade = grade
        self.customWorkTime = customWorkTime
        self.customPauseTime = customPauseTime
    }
    
    // Helper methods if needed
    // e.g., a method to update the timing’s schedule, etc.
}
