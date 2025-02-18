import Foundation
import SwiftData
import Combine
import CoreBluetooth


class DiffuserManager: ObservableObject {
    @Published var diffusers: [Diffuser] = [] // Observable property for UI updates
    private var diffuserMapping: [CBPeripheral: Diffuser] = [:]
    private var modelContext: ModelContext
    private var diffuserAPI: DiffuserAPI?
    private var bluetoothManager: BluetoothManager
    private var subscriptionsSetUp = false
    private var cancellables = Set<AnyCancellable>()
    

    var newDiffuserNameKey: String {
        String(localized: "new_device_name") // ✅ Fetches localized string
    }



    @Published var currentDiffuser: Diffuser?

    init(context: ModelContext, bluetoothManager: BluetoothManager, diffuserAPI: DiffuserAPI) {
        self.bluetoothManager = bluetoothManager
        self.modelContext = context
        self.diffuserAPI = diffuserAPI  // Assign the passed API implementation
        print("DiffuserManager initialized with BluetoothManager: \(Unmanaged.passUnretained(bluetoothManager).toOpaque())")

        // Load any existing diffusers from SwiftData
        loadDiffusers()

        // Set up Combine subscriptions
        setupSubscriptions()

        // Observe changes in `readyToSubscribe`
        self.bluetoothManager.$readyToSubscribe
            .removeDuplicates()
            .sink { [weak self] isReady in
                guard let self = self else { return }
                print("readyToSubscribe changed: \(isReady)")
                if isReady {
                    print("BluetoothManager is ready. Setting up subscriptions.")
                    self.setupSubscriptions()
                    self.updateConnectionStatus(for: self.bluetoothManager.connectedPeripheral)
                } else {
                    print("BluetoothManager not ready. Subscriptions will not be set up.")
                }
            }
            .store(in: &cancellables)

        // If the BluetoothManager was already ready, set up immediately
        if bluetoothManager.readyToSubscribe {
            print("readyToSubscribe was already true. Setting up subscriptions.")
            setupSubscriptions()
        }
    }

    // MARK: - Setup Subscriptions

    func setupSubscriptions() {
        guard !subscriptionsSetUp else {
            print("Subscriptions already set up.")
            return
        }
        subscriptionsSetUp = true

        print("Setting up subscriptions. State: \(bluetoothManager.state), Peripheral: \(bluetoothManager.connectedPeripheral?.name ?? "None")")

        // Observe changes to the connected peripheral
        bluetoothManager.$connectedPeripheral
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectedPeripheral in
                guard let self = self else { return }
                self.updateConnectionStatus(for: connectedPeripheral)
            }
            .store(in: &cancellables)
        
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

    // MARK: - Peripheral Handling

    // Called when a new or existing peripheral is connected
    func handlePeripheralConnected(_ peripheral: CBPeripheral) {
        guard let diffuser = findOrCreateDiffuser(for: peripheral) else { return }
        // We can optionally set currentDiffuser to the newly linked or found diffuser
        currentDiffuser = diffuser
    }

    // MARK: - Find or Create Diffuser
    private func findOrCreateDiffuser(for peripheral: CBPeripheral) -> Diffuser? {
        let peripheralUUID = peripheral.identifier.uuidString

        // Check if the diffuser already exists
        if let existingDiffuser = diffusers.first(where: { $0.peripheralUUID == peripheralUUID }) {
            // Update the mapping to ensure we have the latest reference
            diffuserMapping[peripheral] = existingDiffuser
            print("🔄 Existing diffuser found for \(peripheralUUID). Returning the existing instance.")
            return existingDiffuser
        }
        
        
        // If it does not exist, create a new one
        let newDiffuser = Diffuser(
            name: newDiffuserNameKey,
            isConnected: true,
            modelNumber: "Unknown",
            serialNumber: peripheralUUID,
            timerSetting: 30,
            peripheralUUID: peripheralUUID
        )

        modelContext.insert(newDiffuser)
        diffusers.append(newDiffuser)
        diffuserMapping[peripheral] = newDiffuser

        do {
            try modelContext.save()
            print("✅ Created and linked new diffuser \(newDiffuser.id) to peripheral \(peripheral.identifier)")
            return newDiffuser
        } catch {
            print("❌ Failed to save new diffuser for \(peripheral.identifier): \(error)")
            return nil
        }
    }

    
    func findDiffuser(by peripheralUUID: String) -> Diffuser? {
        // Example: look for a diffuser with a matching peripheralUUID
        diffusers.first { $0.peripheralUUID == peripheralUUID }
    }
    
    // MARK: - Handle Fragrance Timing
    func handleFragranceTimingResponse(_ response: FragranceTimingResponse, peripheral: CBPeripheral) {
        guard let diffuser = findOrCreateDiffuser(for: peripheral) else {
            print("Could not find or create diffuser for peripheral: \(peripheral.identifier)")
            return
        }

        // Create a new Timing object from the response
        let newTiming = Timing(
            number: Int(response.timingNumber),
            powerOn: response.powerOnTime,
            powerOff: response.powerOffTime,
            daysOfOperation: response.daysOfOperation,
            gradeMode: response.gradeMode,
            grade: Int(response.grade),
            customWorkTime: Int(response.customWorkTime),
            customPauseTime: Int(response.customPauseTime)
        )

        // If there's a 9-timing limit, enforce it here
        if diffuser.timings.count < 6 {
            diffuser.timings.append(newTiming)
            modelContext.insert(newTiming)
            do {
                try modelContext.save()
                print("Stored timing #\(newTiming.number) for diffuser \(diffuser.id).")
            } catch {
                print("Error saving context after adding timing: \(error)")
            }
        } else {
            print("Diffuser \(diffuser.id) already has 9 timings. Skipping.")
        }
    }

    func updateTimings(for peripheralUUID: String) {
        guard let peripheral = bluetoothManager.connectedPeripheral,
              peripheral.identifier.uuidString == peripheralUUID else {
            print("❌ No connected peripheral found for UUID: \(peripheralUUID)")
            return
        }
        
        guard let diffuser = findDiffuser(by: peripheralUUID) else {
            print("❌ Could not find diffuser for peripheral: \(peripheralUUID)")
            return
        }
        
        // Clear existing timings before refreshing
        diffuser.timings.removeAll()
        print("🗑 Cleared existing timings for diffuser: \(diffuser.id)")
        
        // Use the BluetoothManager’s method to load settings
        bluetoothManager.loadDiffuserSettings()
    }


    

    
    
    // MARK: - Equipment / Machine Model / Switch / Clock

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

    
    private func updateConnectionStatus(for connectedPeripheral: CBPeripheral?) {
        for diffuser in diffusers {
            diffuser.isConnected = (diffuser.peripheralUUID == connectedPeripheral?.identifier.uuidString)
        }
        saveContext()
        print("✅ Updated connection status for all diffusers.")
    }
    // MARK: - CRUD

    
    func addDiffuser(name: String, isConnected: Bool, modelNumber: String, serialNumber: String, timerSetting: Int) {
        let newDiffuser = Diffuser(
            name: name,
            isConnected: isConnected,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            timerSetting: timerSetting
        )

        modelContext.insert(newDiffuser)
        diffusers.append(newDiffuser)
        currentDiffuser = newDiffuser
        saveContext()
    }

    func removeDiffuser(_ diffuser: Diffuser) {
        modelContext.delete(diffuser)
        diffusers.removeAll { $0.id == diffuser.id }
        if diffuser.id == currentDiffuser?.id {
            currentDiffuser = nil
        }
        saveContext()
    }
    
    

    // MARK: - Persistence

    private func loadDiffusers() {
        do {
            let fetchDescriptor = FetchDescriptor<Diffuser>()
            let allDiffusers = try modelContext.fetch(fetchDescriptor)
            self.diffusers = allDiffusers
            // Optional: Rebuild your diffuserMapping if you store references to peripherals
        } catch {
            print("Error loading diffusers: \(error)")
        }
    }
    
    
    func attemptReconnectionForAllSavedDiffusers() {
        print("🔄 Attempting reconnection for all saved diffusers...")

        for diffuser in diffusers {
            guard let diffuserUUID = diffuser.peripheralUUID else {
                print("⚠️ Skipping diffuser \(diffuser.name) due to missing UUID.")
                continue
            }

            // Check if the peripheral is already connected
            if diffuser.isConnected {
                print("✅ Diffuser \(diffuser.name) is already connected. Skipping reconnection.")
                continue
            }

            bluetoothManager.reconnectToPeripheral(with: diffuserUUID) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let peripheral):
                    print("✅ Successfully reconnected to peripheral: \(peripheral.name ?? "Unnamed Device")")

                    diffuser.isConnected = true
                    diffuser.peripheralUUID = peripheral.identifier.uuidString
                    self.currentDiffuser = diffuser
                    self.saveContext()
                    print("🔗 Re-linked diffuser \(diffuser.id) to reconnected peripheral.")

                    // Reload diffuser settings after reconnection
                    //self.updateTimings(for: diffuserUUID)


                case .failure(let error):
                    print("❌ Failed to reconnect to \(diffuser.name): \(error.localizedDescription)")
                    diffuser.isConnected = false
                    self.saveContext()
                    print("📴 Marked diffuser \(diffuser.id) as disconnected.")
                }
            }
        }
    }
    
    func reconnectToPeripheral(with uuid: String, completion: @escaping (Result<CBPeripheral, Error>) -> Void) {
        bluetoothManager.reconnectToPeripheral(with: uuid, completion: completion)
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
