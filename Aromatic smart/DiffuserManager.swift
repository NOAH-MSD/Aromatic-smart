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
    @Published var diffuserTimings: [String: [Timing]] = [:]

    @Published var currentDiffuser: Diffuser?

    init(context: ModelContext, bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
        self.modelContext = context
        print("DiffuserManager initialized with BluetoothManager: \(Unmanaged.passUnretained(bluetoothManager).toOpaque())")
        loadDiffusers() // Load initial data from SwiftData
        setupSubscriptions()

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
    
    // Link a peripheral to a diffuser by setting its peripheralUUID
    func linkPeripheral(_ peripheral: CBPeripheral, to diffuser: Diffuser) {
        diffuser.peripheralUUID = peripheral.identifier.uuidString
    }

    // Handle a newly connected peripheral:
    // If we have an existing diffuser, link it. Otherwise, create a new diffuser and map it.
    func handlePeripheralConnected(_ peripheral: CBPeripheral) {
        if let existingDiffuser = diffuserMapping[peripheral] {
            // Existing diffuser found, just update peripheralUUID if needed
            existingDiffuser.peripheralUUID = peripheral.identifier.uuidString
            print("Linked existing diffuser \(existingDiffuser.id) to peripheral \(peripheral.identifier)")
        } else {
            // Create a new diffuser including the peripheralUUID
            let newDiffuser = Diffuser(
                name: "New Diffuser",
                isConnected: true,
                modelNumber: "Unknown",
                serialNumber: peripheral.identifier.uuidString,
                timerSetting: 30,
                peripheralUUID: peripheral.identifier.uuidString // Passing peripheralUUID here
            )
            modelContext.insert(newDiffuser)
            diffusers.append(newDiffuser)
            diffuserMapping[peripheral] = newDiffuser
            currentDiffuser = newDiffuser
            print("Created and linked new diffuser \(newDiffuser.id) to peripheral \(peripheral.identifier)")
        }
    }

    func setupSubscriptions() {
        // Ensure subscriptions are only set up once
        guard !subscriptionsSetUp else {
            print("Subscriptions already set up.")
            return
        }
        subscriptionsSetUp = true

        print("Setting up subscriptions. State: \(bluetoothManager.state), Peripheral: \(bluetoothManager.connectedPeripheral?.name ?? "None")")

        // Authentication response subscription
        bluetoothManager.authenticationResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self, let connectedPeripheral = self.bluetoothManager.connectedPeripheral else { return }
                print("setupSubscriptions DiffuserManager received authentication response. Version: \(response.version), Code: \(String(describing: response.code))")
                self.handlePeripheralConnected(connectedPeripheral)
                
                
            }
            .store(in: &cancellables)

        // Equipment version subscription
        bluetoothManager.equipmentVersionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("setupSubscriptions Equipment version response received: \(response.version)")
                self.handleEquipmentVersionResponse(response)
            }
            .store(in: &cancellables)

        // Machine model subscription
        bluetoothManager.machineModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("setupSubscriptions Machine model response received: \(response.model)")
                self.handleMachineModelResponse(response)
            }
            .store(in: &cancellables)

        // Fragrance timing subscription
        bluetoothManager.fragranceTimingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self, let connectedPeripheral = self.bluetoothManager.connectedPeripheral else { return }
                print("setupSubscriptions Fragrance timing response received: \(response)")
                self.handleFragranceTimingResponse(response, peripheral: connectedPeripheral)
            }
            .store(in: &cancellables)

        // Main switch subscription
        bluetoothManager.mainSwitchPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("setupSubscriptions Main switch response received: \(response)")
                self.updateDiffuserWithMainSwitch(response)
            }
            .store(in: &cancellables)

        // Clock subscription
        bluetoothManager.clockResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                print("setupSubscriptions Clock response received: \(response)")
                self.updateDiffuserWithClock(response)
            }
            .store(in: &cancellables)

        print("setupSubscriptions Subscriptions successfully set up.")
    }

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

    func removeDiffuser(_ diffuser: Diffuser) {
        modelContext.delete(diffuser) // Remove from SwiftData
        diffusers.removeAll { $0.id == diffuser.id } // Update the published array
        if diffuser.id == currentDiffuser?.id {
            currentDiffuser = nil
        }
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

    func handleFragranceTimingResponse(_ response: FragranceTimingResponse, peripheral: CBPeripheral) {
        let peripheralUUID = peripheral.identifier.uuidString
        let timing = Timing(
            number: Int(response.timingNumber),
            powerOn: response.powerOnTime,
            powerOff: response.powerOffTime,
            daysOfOperation: response.daysOfOperation,
            gradeMode: response.gradeMode,
            grade: Int(response.grade),
            customWorkTime: Int(response.customWorkTime),
            customPauseTime: Int(response.customPauseTime)
        )

        if diffuserTimings[peripheralUUID] == nil {
            diffuserTimings[peripheralUUID] = []
        }

        diffuserTimings[peripheralUUID]?.append(timing)
        print("📀 timing for UUID \(peripheralUUID): \(timing)")
    }

    private func updateDiffuserWithMainSwitch(_ response: MainSwitchResponse) {
        guard let current = currentDiffuser else {
            print("No current diffuser to update main switch.")
            return
        }
        current.mainSwitch = response.mainSwitch
        current.fanStatus = response.fanStatus
        saveContext()
        print("Updated main switch status in current diffuser.")
    }

    private func updateDiffuserWithClock(_ response: ClockResponse) {
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
