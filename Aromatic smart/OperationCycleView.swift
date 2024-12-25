import SwiftUI

struct OperationCycleView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Bindable var timing: Timing

    @State private var powerOnDate: Date
    @State private var powerOffDate: Date
    @State private var selectedDays: Set<String>
    @State private var selectedIntensity: Int
    @State private var fanEnabled: Bool

    // MARK: - Init
    init(timing: Timing) {
        self._timing = Bindable(timing)
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
                        .onChange(of: powerOnDate) { _ in updateSettings() }

                    Divider().frame(height: 100)

                    TimePicker(title: "End Time", date: $powerOffDate)
                        .onChange(of: powerOffDate) { _ in updateSettings() }
                }
            }

            // Fan Toggle Section
            Section(header: Text("Fan Control")) {
                Toggle("Fan Status", isOn: $fanEnabled)
                    .onChange(of: fanEnabled) { _ in updateSettings() }
            }

            // Intensity Picker Section
            Section(header: Text("Intensity Level")) {
                Picker("Select Intensity", selection: $selectedIntensity) {
                    ForEach(0..<4) { grade in
                        Text(gradeName(for: grade)).tag(grade)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedIntensity) { _ in updateSettings() }
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
                        updateSettings()
                    }
                }
            }
        }
        .navigationTitle("Operation Cycle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateSettings() // Initial update to synchronize the view
        }
    }

    // MARK: - Helper Functions
    private func gradeName(for grade: Int) -> String {
        switch grade {
        case 3: return "Jet"
        case 2: return "High"
        case 1: return "Mid"
        default: return "Low"
        }
    }

    private func updateSettings() {
        guard let connectedPeripheral = bluetoothManager.connectedPeripheral,
              let characteristic = bluetoothManager.pairingCharacteristic else {
            print("Error: Not connected to a diffuser.")
            return
        }

        // Build the command based on current settings
        let command = buildCommand()

        // Send the command using diffuserAPI
        bluetoothManager.diffuserAPI?.writeAndVerifySettings(
            peripheral: connectedPeripheral,
            characteristic: characteristic,
            writeCommand: command
        )
    }

    private func buildCommand() -> [UInt8] {
        // Extract time components
        let powerOnHour = UInt8(Calendar.current.component(.hour, from: powerOnDate))
        let powerOnMinute = UInt8(Calendar.current.component(.minute, from: powerOnDate))
        let powerOffHour = UInt8(Calendar.current.component(.hour, from: powerOffDate))
        let powerOffMinute = UInt8(Calendar.current.component(.minute, from: powerOffDate))

        // Convert days to a bitmask
        let daysBitmask = daysToBitmask(selectedDays)

        // Determine grade mode
        let gradeMode: UInt8 = selectedIntensity > 0 ? 0 : 1
        let grade: UInt8 = UInt8(selectedIntensity)
        let fanSwitch: UInt8 = fanEnabled ? 1 : 0

        // Construct the command array
        return [0x4A, 0x01, 0x01, powerOnHour, powerOnMinute, powerOffHour, powerOffMinute, daysBitmask, gradeMode, grade, fanSwitch]
    }

    private func daysToBitmask(_ days: Set<String>) -> UInt8 {
        var bitmask: UInt8 = 0
        let daysOrder = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        for (index, day) in daysOrder.enumerated() {
            if days.contains(day) {
                bitmask |= (1 << index)
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

extension DateFormatter {
    static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

