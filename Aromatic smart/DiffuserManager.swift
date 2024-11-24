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
