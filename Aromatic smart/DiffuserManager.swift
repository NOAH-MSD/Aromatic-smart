import Foundation
import SwiftData
import Combine
import CoreBluetooth

class DiffuserManager: ObservableObject {
    @Published var diffusers: [Diffuser] = [] // Observable property for UI updates
    private var diffuserMapping: [CBPeripheral: Diffuser] = [:]
    private var modelContext: ModelContext
    private var bluetoothManager: BluetoothManager
    private var cancellables = Set<AnyCancellable>()
    @Published private var currentDiffuser: Diffuser?

    init(context: ModelContext, bluetoothManager: BluetoothManager) {
        self.modelContext = context
        self.bluetoothManager = bluetoothManager
        loadDiffusers() // Load initial data from SwiftData
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Subscribe to BluetoothManager's publishers

        bluetoothManager.authenticationResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("DiffuserManager Received authentication response: \(response)")
                // Example: Create a diffuser when an authentication response is received
                let name = "Diffuser \(UUID().uuidString.prefix(5))" // Generate a temporary name
                let modelNumber = response.version
                let serialNumber = UUID().uuidString
                let timerSetting = 30 // Default timer setting
                let isConnected = true // Assume connected if the response is received
                
                self.addDiffuser(
                    name: name,
                    isConnected: isConnected,
                    modelNumber: modelNumber,
                    serialNumber: serialNumber,
                    timerSetting: timerSetting
                )
            }
            .store(in: &cancellables)

        // Equipment version response
        bluetoothManager.equipmentVersionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                // Update the model number in currentDiffuser
                self.currentDiffuser?.modelNumber = response.version
                self.saveContext()
            }
            .store(in: &cancellables)

        // Machine model response
        bluetoothManager.machineModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                self.currentDiffuser?.modelNumber = response.model
                self.saveContext()
            }
            .store(in: &cancellables)

        // Fragrance timing response
        bluetoothManager.fragranceTimingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                if let diffuser = self.currentDiffuser {
                    diffuser.powerOn = response.powerOnTime
                    diffuser.powerOff = response.powerOffTime
                    diffuser.daysOfOperation = response.daysOfOperation
                    diffuser.gradeMode = response.gradeMode
                    diffuser.grade = Int(response.grade)
                    diffuser.customWorkTime = Int(response.customWorkTime)
                    diffuser.customPauseTime = Int(response.customPauseTime)
                    self.saveContext()
                }
            }
            .store(in: &cancellables)

        // Main switch response
        bluetoothManager.mainSwitchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                if let diffuser = self.currentDiffuser {
                    diffuser.mainSwitch = response.mainSwitch
                    diffuser.fanStatus = response.fanStatus
                    self.saveContext()
                }
            }
            .store(in: &cancellables)

        // Clock response
        bluetoothManager.clockResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                if let diffuser = self.currentDiffuser {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let date = formatter.date(from: response.currentTime) {
                        diffuser.clockTime = date
                        self.saveContext()
                    }
                }
            }
            .store(in: &cancellables)

        // Add other subscriptions as needed...
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
        currentDiffuser = newDiffuser
    }

    // Remove a diffuser from the list and SwiftData
    func removeDiffuser(_ diffuser: Diffuser) {
        modelContext.delete(diffuser) // Remove from SwiftData
        diffusers.removeAll { $0.id == diffuser.id } // Update the published array
        if diffuser.id == currentDiffuser?.id {
            currentDiffuser = nil
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

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
