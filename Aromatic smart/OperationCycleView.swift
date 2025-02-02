import SwiftUI

struct OperationCycleView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Bindable var timing: Timing

    // Local states for UI
    @State private var timingNumber: UInt8
    @State private var powerOnDate: Date
    @State private var powerOffDate: Date
    @State private var selectedDays: Set<String>
    @State private var selectedIntensity: Int
    @State private var fanEnabled: Bool

    // MARK: - Init
    init(timing: Timing) {
        self._timing = Bindable(timing)
        _timingNumber = State(initialValue: UInt8(timing.number))
        _powerOnDate = State(initialValue: DateFormatter.timeFormatter.date(from: timing.powerOn) ?? Date())
        _powerOffDate = State(initialValue: DateFormatter.timeFormatter.date(from: timing.powerOff) ?? Date())
        _selectedDays = State(initialValue: Set(timing.daysOfOperation))
        _selectedIntensity = State(initialValue: timing.grade)
        _fanEnabled = State(initialValue: timing.fanSwitch)
    }

    // MARK: - Body
    var body: some View {
        List {
            // Time Pickers Section
            Section(header: Text("Time Settings")) {
                HStack(spacing: 20) {
                    TimePicker(title: "Start Time", date: $powerOnDate)
                    Divider().frame(height: 100)
                    TimePicker(title: "End Time", date: $powerOffDate)
                }
            }

            // Fan Toggle Section
            Section(header: Text("Fan Control")) {
                Toggle("Fan Status", isOn: $fanEnabled)
            }

            // Intensity Picker Section
            Section(header: Text("Intensity Level")) {
                Picker("Select Intensity", selection: $selectedIntensity) {
                    ForEach(0..<4) { grade in
                        Text(gradeName(for: grade)).tag(grade)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            // Days of Operation Section
            Section(header: Text("Days of Operation")) {
                ForEach(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], id: \.self) { day in
                    HStack {
                        Text(day)
                        Spacer()
                        if selectedDays.contains(day) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }
                }
            }

            // Save Button
            Section {
                Button(action: {
                    saveSettings()
                }) {
                    Text("Save Settings")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Operation Cycle number: \(timing.number)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Optionally do an initial sync if needed
        }
    }

    // MARK: - Helper Functions

    /// Returns a user-friendly name for a given grade/intensity level
    private func gradeName(for grade: Int) -> String {
        switch grade {
        case 3: return "Jet"
        case 2: return "High"
        case 1: return "Mid"
        default: return "Low"
        }
    }

    /// Called when user taps "Save Settings"
    private func saveSettings() {
        // 1. Update timing with final states
        timing.powerOn = DateFormatter.timeFormatter.string(from: powerOnDate)
        timing.powerOff = DateFormatter.timeFormatter.string(from: powerOffDate)
        timing.daysOfOperation = Array(selectedDays)
        timing.grade = selectedIntensity
        timing.fanSwitch = fanEnabled

        // 2. Build final command
        let command = buildCommand()
        
        let StaticExampleCommand: [UInt8] = [
            0x2a, // Opcode
            0x01, // Fragrance type
            0x02, // Non-specific timing bytes
            0x01, // Grade mode (custom)
            0x00, // Fan switch (off)
            0x03, // Timing number
            0x08, // Additional flags
            0x00, 0x16, // Power-on time: 00:22
            0x08, 0x19, // Power-off time: 08:25
            0x3E, // Days of operation: Monday–Friday
            0x02, // Grade (intensity level)
            0x00, 0x19, // Custom work time: 25 seconds
            0x00, 0x50  // Custom pause time: 80 seconds
        ]

        // 3. Instead of calling `writeAndVerifySettings`, we do `writePKOCAndWaitForAck`.
        sendWriteCommand(command: command, timeout: 8.0) { success in
            if success {
                print("✅ ACK received for PKOC command!")
            } else {
                print("❌ Timed out or failed to receive ACK.")
            }
        }
    }
    
    
    private func sendWriteCommand(
        command: [UInt8],
        expectsAck: Bool = false, // Default for Write Command is no ACK
        timeout: TimeInterval = 5.0,
        completion: @escaping (Bool) -> Void
    ) {
        // 1. Ensure we can write to the device
        guard let peripheral = bluetoothManager.connectedPeripheral,
              let characteristic = bluetoothManager.pairingCharacteristic else {
            print("❌ Error: No connected peripheral or pairing characteristic. Cannot write.")
            completion(false)
            return
        }

        // 2. Convert the command to Data
        let data = Data(command)

        // 3. Handle acknowledgment if required
        if expectsAck {
            // Store completion callback in BluetoothManager to handle the acknowledgment later
            bluetoothManager.ackCompletion = { success in
                completion(success)
            }

            // Start a timeout timer to handle cases where no acknowledgment is received
            bluetoothManager.ackTimer?.invalidate() // Cancel any existing timer
            bluetoothManager.ackTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak bluetoothManager] _ in
                print("❌ Timeout waiting for ACK.")
                bluetoothManager?.ackCompletion?(false)
                bluetoothManager?.ackCompletion = nil
            }
        }

        // 4. Write the command as a Write Command
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        let hex = data.map { String(format: "%02x", $0) }.joined(separator: " ")
        print("📤 Sent command: [\(hex)] \(expectsAck ? " (Waiting for ACK)" : "")")

        // 5. If no ACK is expected, complete immediately
        if !expectsAck {
            completion(true)
        }
    }

    /// Constructs the BLE command from the current states
    private func buildCommand() -> [UInt8] {
        // Extract time components from the selected dates.
        let powerOnHour = UInt8(Calendar.current.component(.hour, from: powerOnDate))
        let powerOnMinute = UInt8(Calendar.current.component(.minute, from: powerOnDate))
        let powerOffHour = UInt8(Calendar.current.component(.hour, from: powerOffDate))
        let powerOffMinute = UInt8(Calendar.current.component(.minute, from: powerOffDate))
        
        // Compute the bitmask for days of operation.
        let daysBitmask = daysToBitmask(selectedDays)
        
        // D1: Fragrance type number (here fixed to 1).
        let fragranceType: UInt8 = 0x01
        // D2: Number of non-specific timing bytes.
        let nonSpecificTimingBytes: UInt8 = 0x02
        // D3: Master switch: always atomization on (bit0 = 1), plus fan switch (bit1) if enabled.
        let masterSwitch: UInt8 = fanEnabled ? 0x03 : 0x01
        // D4: Current timing number (read only) from the model.
        let currentTiming: UInt8 = UInt8(timing.number)
        // D5: Timing number to update (using the same timing number).
        let updateTiming: UInt8 = UInt8(timing.number)
        // D6: Timing flags: bit0 (display/delete) and bit1 (timing on) are set; include bit3 (fan on) if enabled.
        let timingFlags: UInt8 = fanEnabled ? (0x03 | 0x08) : 0x03
        // D12: Grade mode. (0 = grade mode; change as needed.)
        let gradeModeField: UInt8 = 0x00
        // D13: Grade (intensity level).
        let grade: UInt8 = UInt8(selectedIntensity)
        
        // D14–D15: Custom work time in 2 bytes.
        let customWorkTimeValue: UInt16 = 10  // For example, 10 seconds.
        let customWorkTimeHigh = UInt8(customWorkTimeValue >> 8)
        let customWorkTimeLow = UInt8(customWorkTimeValue & 0xFF)
        // D16–D17: Custom pause time in 2 bytes.
        let customPauseTimeValue: UInt16 = 100  // For example, 100 seconds.
        let customPauseTimeHigh = UInt8(customPauseTimeValue >> 8)
        let customPauseTimeLow = UInt8(customPauseTimeValue & 0xFF)
        
        return [
            0x2A,                   // Opcode
            fragranceType,          // D1: Fragrance type number
            nonSpecificTimingBytes, // D2: Non-specific timing bytes count
            masterSwitch,           // D3: Fragrance type master switch (atomization on, fan per setting)
            currentTiming,          // D4: Current timing number (read only)
            updateTiming,           // D5: Timing number to update
            timingFlags,            // D6: Timing flags (display/delete, timing on, fan on/off)
            powerOnHour,            // D7: Power on hour
            powerOnMinute,          // D8: Power on minute
            powerOffHour,           // D9: Power off hour
            powerOffMinute,         // D10: Power off minute
            daysBitmask,            // D11: Days of operation bitmask
            gradeModeField,         // D12: Grade mode (0 = grade, 1 = custom)
            grade,                  // D13: Grade (intensity)
            customWorkTimeHigh,     // D14: Custom work time high byte
            customWorkTimeLow,      // D15: Custom work time low byte
            customPauseTimeHigh,    // D16: Custom pause time high byte
            customPauseTimeLow      // D17: Custom pause time low byte
        ]
    }


    /// Converts a set of day strings into a bitmask
    /// Converts a set of day strings into a bitmask.
    /// - Parameter days: A set of day strings (e.g., ["Monday", "Wednesday"]).
    /// - Returns: A bitmask representing the selected days (e.g., 0b0010010 for Monday and Wednesday).
    private func daysToBitmask(_ days: Set<String>) -> UInt8 {
        // Define the order of days (Sunday is bit 0, Monday is bit 1, etc.)
        let daysOrder = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        // Initialize the bitmask
        var bitmask: UInt8 = 0
        
        // Iterate over the days and set the corresponding bits
        for (index, day) in daysOrder.enumerated() {
            if days.contains(day) {
                bitmask |= (1 << index) // Shift 1 left by the index (1 << 0 = Sunday, 1 << 1 = Monday, etc.)
            } else if !daysOrder.contains(day) {
                print("⚠️ Unrecognized day: \(day). Skipping.")
            }
        }
        
        return bitmask
    }
}

// MARK: - TimePicker Component
struct TimePicker: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        VStack {
            Text(title).font(.headline)
            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .scaleEffect(1.2)
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

