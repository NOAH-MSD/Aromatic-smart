import SwiftUI
import SwiftData

struct OperationCycleView: View {
    @ObservedObject var diffuser: Diffuser

    @State private var powerOnDate: Date
    @State private var powerOffDate: Date
    @State private var selectedIntensity: Intencities = .LOW
    @State private var selectedDays: Set<String>
    @State private var fanEnabled: Bool

    init(diffuser: Diffuser) {
        self.diffuser = diffuser
        _powerOnDate = State(initialValue: DateFormatter.timeFormatter.date(from: diffuser.powerOn) ?? Date())
        _powerOffDate = State(initialValue: DateFormatter.timeFormatter.date(from: diffuser.powerOff) ?? Date())
        _selectedDays = State(initialValue: Set(diffuser.daysOfOperation))
        _fanEnabled = State(initialValue: diffuser.fanSwitch)
    }

    enum Intencities: String, CaseIterable, Identifiable {
        case Jet, HIGH, MID, LOW
        var id: Self { self }
        var displayName: String { rawValue.capitalized }
    }

    var body: some View {
        List {
            // Header Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Operation Cycle")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Configure the device’s operation times, intensity, and other settings.")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
            }

            // Time Pickers Section
            Section {
                HStack(spacing: 20) {
                    TimePicker(title: "Starting Time", date: $powerOnDate)
                        .onChange(of: powerOnDate) { newValue in
                            diffuser.powerOn = DateFormatter.timeFormatter.string(from: newValue)
                        }

                    Divider().frame(height: 100)

                    TimePicker(title: "Ending Time", date: $powerOffDate)
                        .onChange(of: powerOffDate) { newValue in
                            diffuser.powerOff = DateFormatter.timeFormatter.string(from: newValue)
                        }
                }
                
            }
            
            
            // Fan Toggle Section
            Section(header: Text("Fan")) {
                           HStack {
                               Toggle("Fan Status", isOn: $fanEnabled)
                                   .onChange(of: fanEnabled) {
                                       diffuser.fanSwitch = fanEnabled
                                   }

                               Spacer()

                               Image(systemName: fanEnabled ? "fan" : "fan.slash")
                                   .foregroundColor(fanEnabled ? .blue : .gray)
                                   .scaleEffect(1.5)
                                   .animation(.easeInOut, value: fanEnabled)
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
                    case .Jet: diffuser.grade = 3
                    case .HIGH: diffuser.grade = 2
                    case .MID: diffuser.grade = 1
                    case .LOW: diffuser.grade = 0
                    }
                }
            }
            
            Section(header: Text("Custom Durations")) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Work Time (s)").font(.subheadline)
                        Picker("Work Time", selection: $diffuser.customWorkTime) {
                            ForEach(15...600, id: \.self) { value in
                                Text("\(value) s").tag(value)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 100)
                    }

                    VStack(alignment: .leading) {
                        Text("Pause Time (s)").font(.subheadline)
                        Picker("Pause Time", selection: $diffuser.customPauseTime) {
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
            Section(header: Text("Repeat")) {
                ForEach(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], id: \.self) { day in
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
                        diffuser.daysOfOperation = Array(selectedDays)
                    }
                }
            }


                   

            // Custom Durations Section
          
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper for TimeFormatter
extension DateFormatter {
    static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

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
