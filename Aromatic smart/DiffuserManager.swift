import Foundation
import SwiftData
import Combine
import CoreBluetooth

class DiffuserManager: ObservableObject {
    @Published var diffusers: [Diffuser] = [] // Observable property for UI updates
    private var diffuserMapping: [CBPeripheral: Diffuser] = [:]
    private var modelContext: ModelContext
    private var bluetoothManager: BluetoothManager
    private var subscriptionsSetUp = false

    private var cancellables = Set<AnyCancellable>()
    @Published private var currentDiffuser: Diffuser?

    init(context: ModelContext, bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
        self.modelContext = context
        loadDiffusers() // Load initial data from SwiftData
        
        self.bluetoothManager.$readyToSubscribe
            .removeDuplicates() // Prevent duplicate updates
            .sink { [weak self] isReady in
                guard let self = self else { return }
                print("readyToSubscribe changed: \(isReady)")
                if isReady {
                    print("BluetoothManager is ready. Setting up subscriptions.")
                    self.setupSubscriptions() // Explicitly call when ready
                } else {
                    print("BluetoothManager not ready. Subscriptions will not be set up.")
                }
            }
            .store(in: &cancellables)
        
        
        // Manually trigger setupSubscriptions if readyToSubscribe is already true
        if bluetoothManager.readyToSubscribe {
            print("readyToSubscribe was already true. Setting up subscriptions.")
            setupSubscriptions()
        }
        
    }

    func setupSubscriptions() {
        // Ensure subscriptions are only set up once
        guard bluetoothManager.readyToSubscribe else {
            print("setupSubscriptions called prematurely. readyToSubscribe: \(bluetoothManager.readyToSubscribe)")
            return
        }
        guard !subscriptionsSetUp else {
            print("Subscriptions already set up.")
            return
        }

        print("Setting up subscriptions. State: \(bluetoothManager.state), Peripheral: \(bluetoothManager.connectedPeripheral?.name ?? "None")")

        subscriptionsSetUp = true // Prevent multiple setups

        // Authentication response subscription
        bluetoothManager.authenticationResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("Authentication response received. Version: \(response.version), Code: \(String(describing: response.code))")
                self.handleAuthenticationResponse(response)
            }
            .store(in: &cancellables)

        // Equipment version subscription
        bluetoothManager.equipmentVersionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("Equipment version response received: \(response.version)")
                self.handleEquipmentVersionResponse(response)
            }
            .store(in: &cancellables)

        // Machine model subscription
        bluetoothManager.machineModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("Machine model response received: \(response.model)")
                self.handleMachineModelResponse(response)
            }
            .store(in: &cancellables)

        // Fragrance timing subscription
        bluetoothManager.fragranceTimingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("Fragrance timing response received: \(response)")
                self.handleFragranceTimingResponse(response)
            }
            .store(in: &cancellables)

        // Main switch subscription
        bluetoothManager.mainSwitchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("Main switch response received: \(response)")
                self.handleMainSwitchResponse(response)
            }
            .store(in: &cancellables)

        // Clock subscription
        bluetoothManager.clockResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("Clock response received: \(response)")
                self.handleClockResponse(response)
            }
            .store(in: &cancellables)

        print("Subscriptions successfully set up.")
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
    
    
    private func handleAuthenticationResponse(_ response: AuthenticationResponse) {
        let name = "Diffuser \(UUID().uuidString.prefix(5))"
        addDiffuser(
            name: name,
            isConnected: true,
            modelNumber: response.version,
            serialNumber: UUID().uuidString,
            timerSetting: 30
        )
        print("Added diffuser with authentication response.")
    }
    
    private func handleEquipmentVersionResponse(_ response: EquipmentVersionResponse) {
        guard let current = currentDiffuser else {
            print("No current diffuser to update equipment version.")
            return
        }
        current.modelNumber = response.version
        saveContext()
        print("Updated equipment version in current diffuser.")
    }
    
    private func handleMachineModelResponse(_ response: MachineModelResponse) {
        guard let current = currentDiffuser else {
            print("No current diffuser to update machine model.")
            return
        }
        current.modelNumber = response.model
        saveContext()
        print("Updated machine model in current diffuser.")
    }
    
    private func handleFragranceTimingResponse(_ response: FragranceTimingResponse) {
        guard let current = currentDiffuser else {
            print("No current diffuser to update fragrance timing.")
            return
        }
        current.powerOn = response.powerOnTime
        current.powerOff = response.powerOffTime
        current.daysOfOperation = response.daysOfOperation
        current.gradeMode = response.gradeMode
        current.grade = Int(response.grade)
        current.customWorkTime = Int(response.customWorkTime)
        current.customPauseTime = Int(response.customPauseTime)
        saveContext()
        print("Updated fragrance timing in current diffuser.")
    }
    
    private func handleMainSwitchResponse(_ response: MainSwitchResponse) {
        guard let current = currentDiffuser else {
            print("No current diffuser to update main switch.")
            return
        }
        current.mainSwitch = response.mainSwitch
        current.fanStatus = response.fanStatus
        saveContext()
        print("Updated main switch status in current diffuser.")
    }
    
    private func handleClockResponse(_ response: ClockResponse) {
        guard let current = currentDiffuser else {
            print("No current diffuser to update clock.")
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: response.currentTime) {
            current.clockTime = date
            saveContext()
            print("Updated clock time in current diffuser.")
        } else {
            print("Failed to parse clock time from response.")
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
