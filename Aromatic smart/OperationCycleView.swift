import SwiftUI

struct OperationCycleView: View {
    @State private var selectedIntencity: Intencities = .LOW
    
    enum Intencities: String, CaseIterable, Identifiable {
        case Jet , HIGH , MID , LOW
        var id: Self { self }
    }
    @State private var startTime = Date() // State to track the start time
    @State private var stopTime = Date() // State to track the stop time
    @State private var selectedDays: [String: Bool] = [
        NSLocalizedString("every sunday", comment: "كل أحد"): false,
        NSLocalizedString("every monday", comment: "كل إثنين"): false,
        NSLocalizedString("every tuesday", comment: "كل ثلاثاء"): false,
        NSLocalizedString("every wednesday", comment: "كل أربعاء"): false,
        NSLocalizedString("every thursday", comment: "كل خميس"): false,
        NSLocalizedString("every friday", comment: "كل جمعة"): false,
        NSLocalizedString("every saturday", comment: "كل سبت"): false
    ]
    
    // Define the order of the days explicitly
    let dayOrder = [
        NSLocalizedString("every sunday", comment: "كل أحد"),
        NSLocalizedString("every monday", comment: "كل إثنين"),
        NSLocalizedString("every tuesday", comment: "كل ثلاثاء"),
        NSLocalizedString("every wednesday", comment: "كل أربعاء"),
        NSLocalizedString("every thursday", comment: "كل خميس"),
        NSLocalizedString("every friday", comment: "كل جمعة"),
        NSLocalizedString("every saturday", comment: "كل سبت")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: Title and Subtitle
            VStack(alignment: .leading, spacing: 8) {
                Text("Operation cycle")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Choose the time of activity for your device")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            
            // MARK: Time Pickers Section
            HStack(spacing: 20) {
                VStack(spacing: 5) {
                    Text("Starting Time")
                        .font(.headline)
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .scaleEffect(1.2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Divider()
                    .frame(height: 100)
                
                VStack(spacing: 5) {
                    Text("Ending Time")
                        .font(.headline)
                    DatePicker("", selection: $stopTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .scaleEffect(1.2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 16)
            
            // MARK: Repeat Section
            VStack(alignment: .leading, spacing: 8) {
                Text("التكرار")
                    .font(.headline)
                    .padding(.leading, 16)
                
                List {
                    ForEach(dayOrder, id: \.self) { day in
                        HStack {
                            Text(day)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            if selectedDays[day] ?? false {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                        .contentShape(Rectangle()) // Make the entire row tappable
                        .onTapGesture {
                            selectedDays[day]?.toggle()
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 420)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Diffusing Intensity")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading).padding()
                Text("Choose the Diffusing Intensity for your program")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading).padding()
               
                
                HStack{
                    Spacer()
                    Button(action: {
                        print("action")
                    }) {
                        Text("Auto")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        Image(systemName: "fan.badge.automatic.fill")
                    }
                    Spacer()
                }
                
                
                Picker("Intencity", selection: $selectedIntencity) {
                    ForEach(Intencities.allCases) { Intencity in
                        Text(Intencity.rawValue.capitalized)
                        
                    }
                    
                }.pickerStyle(.segmented).padding()
                
            Spacer()
            }//v
            
            
        }
        .padding(.top, 20)
        
        
        
    }
    
    
    
    
    
}

struct OCView: View {
    var body: some View {
        OperationCycleView()
    }
}

struct OCView_Previews: PreviewProvider {
    static var previews: some View {
        OCView()
    }
}
