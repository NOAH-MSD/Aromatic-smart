import SwiftUI

struct OperationCycleView: View {
    @ObservedObject var diffuser: Diffuser
    @State private var powerOnDate: Date
    @State private var powerOffDate: Date
    @State private var selectedIntensity: Intencities = .LOW

    init(diffuser: Diffuser) {
        self.diffuser = diffuser
        _powerOnDate = State(initialValue: DateFormatter.timeFormatter.date(from: diffuser.powerOn) ?? Date())
        _powerOffDate = State(initialValue: DateFormatter.timeFormatter.date(from: diffuser.powerOff) ?? Date())
    }

    enum Intencities: String, CaseIterable, Identifiable {
        case Jet, HIGH, MID, LOW
        var id: Self { self }
        var displayName: String { rawValue.capitalized }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Operation Cycle")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Choose the time of activity for your device")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)

            // Time Pickers
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
            .padding(.horizontal, 16)

            // Intensity Picker
            VStack {
                Text("Intensity Level").font(.headline)
                Picker("Intensity", selection: $selectedIntensity) {
                    ForEach(Intencities.allCases) { intensity in
                        Text(intensity.displayName).tag(intensity)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal, 16)

            // Days of Operation
            VStack(alignment: .leading, spacing: 8) {
                Text("Repeat").font(.headline).padding(.leading, 16)
                List {
                    ForEach(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], id: \.self) { day in
                        Toggle(day, isOn: Binding(
                            get: { diffuser.daysOfOperation.contains(day) },
                            set: { isSelected in
                                if isSelected {
                                    diffuser.daysOfOperation.append(day)
                                } else {
                                    diffuser.daysOfOperation.removeAll { $0 == day }
                                }
                            }
                        ))
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 420)
            }

            // Key-Value Rows
            VStack(spacing: 20) {
                KeyValueRow(key: "Atomization", value: diffuser.atomizationSwitch ? "On" : "Off")
                KeyValueRow(key: "Fan", value: diffuser.fanSwitch ? "On" : "Off")
                KeyValueRow(key: "Power On", value: diffuser.powerOn)
                KeyValueRow(key: "Power Off", value: diffuser.powerOff)
                KeyValueRow(key: "Days of Operation", value: diffuser.daysOfOperation.isEmpty ? "None" : diffuser.daysOfOperation.joined(separator: ", "))
                KeyValueRow(key: "Grade Mode", value: diffuser.gradeMode)
                KeyValueRow(key: "Grade", value: "\(diffuser.grade)")
                KeyValueRow(key: "Custom Work Time", value: "\(diffuser.customWorkTime) seconds")
                KeyValueRow(key: "Custom Pause Time", value: "\(diffuser.customPauseTime) seconds")
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
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

struct KeyValueRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(key):").bold().frame(maxWidth: 150, alignment: .leading)
            Spacer()
            Text(value).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
