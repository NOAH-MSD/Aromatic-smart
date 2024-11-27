import Foundation
import SwiftData

class DiffuserManager: ObservableObject {
    @Published var diffusers: [Diffuser] = [] // Observable property for UI updates
    private var modelContext: ModelContext

    init(context: ModelContext) {
        self.modelContext = context
        loadDiffusers() // Load initial data from SwiftData
    }

    // Add a diffuser to the list and persist it
    func addDiffuser(name: String, isConnected: Bool, modelNumber: String, serialNumber: String, timerSetting: Int) {
        let newDiffuser = Diffuser(
            name: name,
            isConnected: isConnected,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            timerSetting: timerSetting
        )
        
        modelContext.insert(newDiffuser) // Insert into SwiftData
        diffusers.append(newDiffuser) // Update the published array
    }

    // Remove a diffuser from the list and SwiftData
    func removeDiffuser(_ diffuser: Diffuser) {
        modelContext.delete(diffuser) // Remove from SwiftData
        diffusers.removeAll { $0.id == diffuser.id } // Update the published array
    }

    // Update a diffuser object based on the parsed Bluetooth response
    func updateDiffuserModel(from response: String, diffuser: Diffuser) {
        // Parse power on/off times
        if let powerOnMatch = response.range(of: "Power On: (\\d{2}:\\d{2})", options: .regularExpression) {
            diffuser.powerOn = String(response[powerOnMatch])
        }
        if let powerOffMatch = response.range(of: "Power Off: (\\d{2}:\\d{2})", options: .regularExpression) {
            diffuser.powerOff = String(response[powerOffMatch])
        }

        // Parse days of operation
        if let daysMatch = response.range(of: "Days of Operation: ([\\w, ]+)", options: .regularExpression) {
            let daysString = String(response[daysMatch])
            diffuser.daysOfOperation = daysString.components(separatedBy: ", ")
        }

        // Parse grade mode and grade
        if let gradeModeMatch = response.range(of: "Grade Mode: (\\w+)", options: .regularExpression) {
            diffuser.gradeMode = String(response[gradeModeMatch])
        }
        if let gradeMatch = response.range(of: "Grade: (\\d+)", options: .regularExpression) {
            diffuser.grade = Int(String(response[gradeMatch])) ?? 0
        }

        // Parse custom work and pause times
        if let workTimeMatch = response.range(of: "Custom Work Time: (\\d+)", options: .regularExpression) {
            diffuser.customWorkTime = Int(String(response[workTimeMatch])) ?? 0
        }
        if let pauseTimeMatch = response.range(of: "Custom Pause Time: (\\d+)", options: .regularExpression) {
            diffuser.customPauseTime = Int(String(response[pauseTimeMatch])) ?? 0
        }

        // Parse main switch and fan status
        if let mainSwitchMatch = response.range(of: "Main Switch: (On|Off)", options: .regularExpression) {
            diffuser.mainSwitch = String(response[mainSwitchMatch]) == "On"
        }
        if let fanStatusMatch = response.range(of: "Fan Switch: (On|Off)", options: .regularExpression) {
            diffuser.fanStatus = String(response[fanStatusMatch]) == "On"
        }

        // Parse clock time
        if let clockTimeMatch = response.range(of: "Current Time: (\\d{4}-\\d{2}-\\d{2} \\d{1,2}:\\d{2})", options: .regularExpression) {
            let clockTimeString = String(response[clockTimeMatch])
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            diffuser.clockTime = dateFormatter.date(from: clockTimeString)
        }

        // Save updated diffuser to SwiftData
        do {
            try modelContext.save()
        } catch {
            print("Error saving updated diffuser: \(error)")
        }
    }

    private func loadDiffusers() {
        do {
            // Fetch all Diffuser objects using a FetchDescriptor
            let fetchDescriptor = FetchDescriptor<Diffuser>()
            let allDiffusers = try modelContext.fetch(fetchDescriptor)
            self.diffusers = allDiffusers
        } catch {
            print("Error loading diffusers: \(error)")
        }
    }
}
