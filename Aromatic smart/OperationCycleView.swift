import SwiftUI

struct OperationCycleView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\.layoutDirection) var layoutDirection
    @Bindable var timing: Timing
    
    // Local states for UI
    @State private var timingNumber: UInt8
    @State private var powerOnDate: Date
    @State private var powerOffDate: Date
    @State private var selectedDays: Set<String>
    @State private var selectedIntensity: Int
    @State private var fanEnabled: Bool
    @State private var gradeMode: Bool
    
    // MARK: - Init
    init(timing: Timing) {
        self._timing = Bindable(timing)
        _timingNumber = State(initialValue: UInt8(timing.number))
        _powerOnDate = State(initialValue: DateFormatter.timeFormatter.date(from: timing.powerOn) ?? Date())
        _powerOffDate = State(initialValue: DateFormatter.timeFormatter.date(from: timing.powerOff) ?? Date())
        _selectedDays = State(initialValue: Set(timing.daysOfOperation))
        _selectedIntensity = State(initialValue: timing.grade)
        _fanEnabled = State(initialValue: timing.fanSwitch)
        _gradeMode = State(initialValue: timing.gradeMode)
    }
    
    //MARK: Body view
    
    
    var body: some View {
        ZStack {
            // 🌟 Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.122, green: 0.251, blue: 0.565), // Darker blue (Top)
                    Color(red: 0.542, green: 0.678, blue: 1)      // Lighter blue (Bottom)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 22) {
                    // 🌟 Header Section
                    headerView
                    Spacer()

                    
                    

                    
                    // 🌟 Time Settings Section with proper background and rounded corners
                    Section {
                        VStack {
                            Text("Time Settings")
                                .font(Font.custom("DIN Next LT Arabic", size: 14))
                                .foregroundColor(.white.opacity(0.8)).bold()
                            HStack(spacing: 20) {
                                if layoutDirection == .rightToLeft {
                                    TimePicker(title: "End Time", date: $powerOffDate).bold()
 
                                    
                                    
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 1, height: 90)
                                    TimePicker(title: "Start Time", date: $powerOnDate)
                                } else {
                                    TimePicker(title: "Start Time", date: $powerOnDate)
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 1, height: 90)
                                    TimePicker(title: "End Time", date: $powerOffDate)
                                }
                            }
                            .padding()
                            .frame(width: 309, height: 118) // Match width and height from UIKit
                            .background(Color.white.opacity(0.7)) // Same transparency as UIKit view
                            .cornerRadius(25) // Apply rounded corners
                        }
                        .frame(maxWidth: .infinity) // Keep it responsive
                    }


                    
                    // 🌟 Fan Control Section
                    VStack(spacing: 5) {
                        Text("Fan Control")
                            .font(Font.custom("DIN Next LT Arabic", size: 14))
                            .foregroundColor(.white.opacity(0.8)).bold()
                        
                        HStack {
                            Toggle("", isOn: $fanEnabled)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .scaleEffect(1.1)
                            if fanEnabled {
                                Image(systemName: "fan.fill")
                                    .symbolEffect(.bounce, options: .repeat(.periodic(2)))
                                    .padding(.trailing, 10)
                                    .foregroundColor(.blue)
                            }
                            else if !fanEnabled {
                                Image(systemName: "fan")
                                    
                                    .padding(.trailing, 10)
                                    .foregroundColor(Color.gray)
                            }


                       

                            

                                
                            Spacer()
                            Text("Fan state")
                                .font(Font.custom("DIN Next LT Arabic", size: 16))
                                    .foregroundColor(.black)
                                    .bold()
                        }
                        .padding()
                        .frame(width: 309) // Match width & height from UIKit
                        .background(Color.white.opacity(0.7)) // Apply same transparency
                        .cornerRadius(20.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    
                    
                    
                    
                    
                    // 🌟 Perfuming Intensity Section Styled to Match UIKit
                    VStack(spacing: 5) {
                        HStack{
                            Text("Perfuming intensity")
                                .font(Font.custom("DIN Next LT Arabic", size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .bold()
                        }
                        ZStack {
                            // Background Frame
                            RoundedRectangle(cornerRadius: 20.5)
                                .fill(Color.white.opacity(0.7)) // Correct background color from UIKit
                                .frame(width: 309, height: 51)
                            HStack(spacing: 10) {
                                Image(systemName: "dot.radiowaves.left.and.right", variableValue: Double(intensityFactor(for: selectedIntensity))).foregroundColor(Color.blue).symbolEffect(.pulse, options: .repeat(.periodic(1))).padding(.trailing,10)
                                ForEach(["Jet", "High", "Mid", "Low"], id: \.self) { label in
                                    ZStack {
                                        if selectedIntensity == tagFor(label) {
                                            RoundedRectangle(cornerRadius: 11)
                                                .fill(Color.white)
                                                .frame(width: 57, height: 26).scaleEffect(scaleFactor(for: selectedIntensity))
                                                .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1)
                                        }
                                            Text(label)
                                                .font(Font.custom("DIN Next LT Arabic", size: 14))
                                                .foregroundColor(.black)
                                                .bold()
                                    }
                                    .onTapGesture {
                                        selectedIntensity = tagFor(label)
                                    }
                                    if label != "Low" { // Dividers between options
                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(width: 1, height: 17)
                                    }
                                }
                                

                            }
                        }
                    }


                    
                    HStack{
                        Text("Custom Durations")
                            .font(Font.custom("DIN Next LT Arabic", size: 16))
                                .foregroundColor(.black)
                                .bold()
                        Spacer()
                        Toggle("Custom Durations", isOn: $gradeMode)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .scaleEffect(1.1)
                    }.padding()
                        .frame(width: 309) // Match width & height from UIKit
                        .background(Color.white.opacity(0.7)) // Apply same transparency
                        .cornerRadius(20.5)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Custom Durations Section
                    Section() {

                        if gradeMode == true {
                            VStack{
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading) {
                                        Text("Work Time").font(Font.custom("DIN Next LT Arabic", size: 16))
                                            .foregroundColor(.black)
                                            .bold()
                                        Picker("Work Time", selection: $timing.customWorkTime) {
                                            ForEach(15...600, id: \.self) { value in
                                                Text("\(value) s").tag(value)
                                            }
                                        }
                                        .pickerStyle(WheelPickerStyle())
                                        .frame(width: 100, height: 100)
                                    }
                                    
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 1, height: 80)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Pause Time").font(Font.custom("DIN Next LT Arabic", size: 16))
                                            .foregroundColor(.black)
                                            .bold()
                                        Picker("Pause Time", selection: $timing.customPauseTime) {
                                            ForEach(15...600, id: \.self) { value in
                                                Text("\(value) s").tag(value)
                                            }
                                        }
                                        .pickerStyle(WheelPickerStyle())
                                        .frame(width: 100, height: 100)
                                    }
                                }
                            }
                            
                            .frame(width: 309) // Match width and height from UIKit
                            .background(Color.white.opacity(0.7)) // Same transparency as UIKit view
                            .cornerRadius(25) // Apply rounded corners
                        }
                        }
                        
                        

                    
                    
                    
                    
                    // 🌟 Days of Operation Section as vertically arranged buttons with fine dividers
                    VStack(spacing: 5) {
                        Text("Days of operation")
                            .font(Font.custom("DIN Next LT Arabic", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .bold()

                        ZStack {
                            // ✅ Background container with shadow
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.7))
                                

                            VStack(spacing: 5) {
                                ForEach(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], id: \.self) { day in
                                    HStack {
                                        // ✅ **Day Label**
                                        Text(day)
                                            .font(Font.custom("DIN Next LT Arabic", size: 14))
                                            .foregroundColor(.black)
                                            .padding(.leading,20)
                                            

                                        Spacer()

                                        // ✅ **Filled Checkmark for Selected Days**
                                        Image(systemName: selectedDays.contains(day) ? "checkmark" : "circle").contentTransition(.symbolEffect(.replace))
                                            .font(.system(size: 18))
                                            .foregroundColor(selectedDays.contains(day) ? .green : .gray.opacity(0.5))
                                            .padding(.trailing,25)
                                    }
                                    .frame(width: 284, height: 38)
                                    .background(Color(hex: "#E4E4E4")) // ✅ Matches guide color
                                    .cornerRadius(24)
                                    //.padding(.horizontal, 10) // ✅ More padding for better alignment
                                    .onTapGesture {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }

 
                                }
                            }
                            .padding(.vertical, 30) // ✅ Adjust list padding
                        }
                        .frame( minHeight: 270, maxHeight: .infinity) // ✅ Auto-sizing background
                        .frame(width: 309)
                    }



                    
                    Spacer()
                    
                    // 🌟 Save Settings Button
                    Button(action: {}) {
                        Text("Save Settings")
                            .font(Font.custom("DIN Next LT Arabic", size: 18).weight(.medium))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue.opacity(0.9))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                
                .padding(.horizontal, 20)
            }
                
        }
            
    }


    


    
    
    
    
    


    
    private var headerView: some View {
        HStack {
            Text("Operation Cycle \(timing.number)")
                .font(Font.custom("DIN Next LT Arabic", size: 24))
                .foregroundColor(.white).bold()
        }
        .padding([.leading, .trailing], 20)
        .padding(.top, 50)
    }
    


    // MARK: - Helper Functions

    /// Returns a user-friendly name for a given grade/intensity level
    private func gradeName(for grade: Int) -> String {
        switch grade {
        case 3: return "Jet "
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
    
    
    
    private func scaleFactor(for intensity: Int) -> CGFloat {
        switch intensity {
        case 0: return 1.05  // Low - 5% increase
        case 1: return 1.30  // Mid - 10% increase
        case 2: return 1.40  // High - 15% increase
        case 3: return 1.55  // Jet - 20% increase
        default: return 1.0  // Default size
        }
    }
    private func intensityFactor(for intensity: Int) -> Double {
        switch intensity {
        case 0: return 0.1  // Low - 10%
        case 1: return 0.3  // Mid - 20%
        case 2: return 0.6  // High - 50%
        case 3: return 1  // Jet - 80%
        default: return 0.0  // Default (No bars)
        }
    }

    

    // Converts text to the correct tag
    private func tagFor(_ label: String) -> Int {
        switch label {
            case "Jet": return 3
            case "High": return 2
            case "Mid": return 1
            case "Low": return 0
            default: return -1
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
        let gradeModeField: UInt8 = gradeMode ? 0x01 : 0x00
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
            Text(title).font(Font.custom("DIN Next LT Arabic", size: 16))
                .foregroundColor(.black)
                .bold()
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255.0
        g = Double((int >> 8) & 0xFF) / 255.0
        b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}


