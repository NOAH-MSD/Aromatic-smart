import SwiftUI
import SwiftData

struct OperationCycleView: View {
    @Bindable var timing: Timing

    @State private var powerOnDate: Date
    @State private var powerOffDate: Date
    @State private var selectedDays: Set<String>
    @State private var selectedIntensity: Intencities

    // NEW: Local state for fan toggle, since onChange requires an Equatable
    @State private var fanEnabled: Bool

    init(timing: Timing) {
        self._timing = Bindable(timing)

        // Convert timing.powerOn/off to Date
        _powerOnDate = State(initialValue: DateFormatter.timeFormatter.date(from: timing.powerOn) ?? Date())
        _powerOffDate = State(initialValue: DateFormatter.timeFormatter.date(from: timing.powerOff) ?? Date())

        // Days of operation as a set
        _selectedDays = State(initialValue: Set(timing.daysOfOperation))

        // Convert timing.grade to Intensity
        if timing.grade == 3 {
            _selectedIntensity = State(initialValue: .Jet)
        } else if timing.grade == 2 {
            _selectedIntensity = State(initialValue: .HIGH)
        } else if timing.grade == 1 {
            _selectedIntensity = State(initialValue: .MID)
        } else {
            _selectedIntensity = State(initialValue: .LOW)
        }

        // Initialize fanEnabled from timing
        _fanEnabled = State(initialValue: timing.fanSwitch)
    }

    enum Intencities: String, CaseIterable, Identifiable {
        case Jet, HIGH, MID, LOW
        var id: Self { self }
        var displayName: String { rawValue.capitalized }
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Operation Cycle")
                        .font(.title.bold())
                    Text("Configure the device’s operation times, intensity, fan, and other settings.")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }

            // Time Pickers Section
            Section {
                HStack(spacing: 20) {
                    TimePicker(title: "Starting Time", date: $powerOnDate)
                        .onChange(of: powerOnDate) { newDate in
                            timing.powerOn = DateFormatter.timeFormatter.string(from: newDate)
                        }

                    Divider().frame(height: 100)

                    TimePicker(title: "Ending Time", date: $powerOffDate)
                        .onChange(of: powerOffDate) { newDate in
                            timing.powerOff = DateFormatter.timeFormatter.string(from: newDate)
                        }
                }
            }

            // Fan Toggle Section
            Section(header: Text("Fan")) {
                Toggle("Fan Status", isOn: $fanEnabled)
                    .onChange(of: fanEnabled) { newValue in
                        // Manually sync back to timing.fanSwitch
                        timing.fanSwitch = newValue
                    }
            }

            // Intensity Section
            Section(header: Text("Intensity Level")) {
                Picker("Intensity", selection: $selectedIntensity) {
                    ForEach(Intencities.allCases) { intensity in
                        Text(intensity.displayName).tag(intensity)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedIntensity) { newIntensity in
                    switch newIntensity {
                    case .Jet: timing.grade = 3
                    case .HIGH: timing.grade = 2
                    case .MID:  timing.grade = 1
                    case .LOW:  timing.grade = 0
                    }
                }
            }

            // Custom Durations Section
            Section(header: Text("Custom Durations")) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Work Time (s)").font(.subheadline)
                        Picker("Work Time", selection: $timing.customWorkTime) {
                            ForEach(15...600, id: \.self) { value in
                                Text("\(value) s").tag(value)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 100)
                    }

                    VStack(alignment: .leading) {
                        Text("Pause Time (s)").font(.subheadline)
                        Picker("Pause Time", selection: $timing.customPauseTime) {
                            ForEach(15...600, id: \.self) { value in
                                Text("\(value) s").tag(value)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 100)
                    }
                }
                .padding(.vertical, 8)
            }

            // Days of Operation Section
            Section(header: Text("Days of Operation")) {
                ForEach(["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"], id: \.self) { day in
                    HStack {
                        Text("Every \(day)")
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
                        timing.daysOfOperation = Array(selectedDays)
                    }
                }
            }
        }
        .navigationTitle("Cycle #\(timing.number)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper

extension DateFormatter {
    static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

/// Simple time picker component
struct TimePicker: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 5) {
            Text(title).font(.headline)
            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .scaleEffect(1.2)
        }
    }
}
