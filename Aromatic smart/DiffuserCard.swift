import SwiftUI
import SwiftData

struct DiffuserCard: View {
    let diffuser: Diffuser
    @State private var selectedDate: Date = Date()
    @EnvironmentObject var diffuserManager: DiffuserManager // Access the manager
    @Namespace private var animationNamespace
    @State private var isFlipped = false // Track flip state
    @State private var isSnoozeEnabled: Bool = false
    @State private var selectedRepeat: String = "مطلقاً"
    @State private var alarmLabel: String = "تسمية المنبه"
    @State private var alarmSound: String = "الافتتاحية"
    @State private var selectedProgram: Programs = .A
    @State private var selectedIntencity = "1"
    
    
    enum Programs: String, CaseIterable, Identifiable {
        case A, B, C,D
        var id: Self { self }
    }
    var body: some View {
        ZStack {
            // Back of the Card (Settings View)
            VStack(spacing: 14) {
                Text("إعدادات الجهاز")
                    .font(.title2).bold().foregroundColor(.white)
                
                HStack{
                    Text("Programs :")
                        .font(.headline).foregroundColor(.white).padding(.leading)
                    Spacer()
                }
                HStack(spacing: 10) {
                    ForEach(Programs.allCases) { program in
                        Text(program.rawValue.capitalized)
                            .font(.headline)
                            .foregroundColor(selectedProgram == program ? .white : .gray) // White for unselected, black for selected
                            .padding(12)
                            .frame(maxWidth: .infinity) // Equal spacing
                            .background(selectedProgram == program ? Color(red: 15 / 255, green: 32 / 255, blue: 71 / 255) : Color.clear) // Highlight selected with white background
                            .cornerRadius(8) // Rounded corners
                            .onTapGesture {
                                selectedProgram = program // Update selected program on tap
                            }
                    }
                }
                .padding(5)
                .background(Color(UIColor.secondarySystemBackground)) // Match your theme background

                    
                VStack(alignment: .leading, spacing: 8) {

                    
                    // Repeat Row
                    NavigationLink(destination: OperationCycleView())
                    {
                        HStack {
                            Text("Operation cycles")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Text("from 1pm to 10pm in selected days")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                    }

                    
                    // Repeat Row
                    NavigationLink(destination: DiffusingIntensityView())
                    {
                        HStack {
                            Text("Diffusing Intencity")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Text("100%")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                    }

                    // Delete Button
                    HStack{
                        Button {
                                isFlipped.toggle() // Toggle flip state
                        } label: {
                            Text("Confirm")
                                .foregroundColor(.green)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(8)
                        }

                        Button(action: {
                            diffuserManager.removeDiffuser(diffuser) // Call the manager to remove this diffuser
                        }){
                            Text("Delete Device")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        
                    }
                    .font(.subheadline)
                    .padding()
                } // end of VStack
            } //end of Hstack
            
            
            .frame(width: UIScreen.main.bounds.width * 0.9, height: 395)
            .background(Color(red: 15 / 255, green: 32 / 255, blue: 71 / 255))
            .cornerRadius(25)
            .shadow(radius: 5)
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : -90),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
            .opacity(isFlipped ? 1 : 0)
            .animation(isFlipped ? .linear.delay(0.35) : .linear, value: isFlipped)

            //-------------------------------------------
            // Front of the Card (Device Info View)
            VStack(spacing: 14) {
                Text(diffuser.name)
                    .font(.title2).bold().foregroundColor(.white)

                // Device Image
                Image("AF300")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .cornerRadius(50)

                // Device Status
                Text(diffuser.isConnected ? "الحالة: متصل" : "الحالة: غير متصل")
                    .font(.body)
                    .foregroundColor(diffuser.isConnected ? .green : .red)

                // Additional Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model Number: \(diffuser.modelNumber)").foregroundColor(.white)
                    Text("Serial Number: \(diffuser.serialNumber)").foregroundColor(.white)
                    Text("ⓘ اضغط لضبط مؤقت التشغيل").foregroundColor(.white)
                }
                .font(.subheadline)
                .padding(.top, 16)
            }
            .frame(width: UIScreen.main.bounds.width * 0.9, height: 409)
            .background(diffuser.isConnected ? Color(red: 21 / 255, green: 47 / 255, blue: 119 / 255).opacity(0.9) : Color.gray.opacity(0.2))
            .cornerRadius(25)
            .shadow(radius: 5)
            .rotation3DEffect(
                .degrees(isFlipped ? 90 : 0),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
            .opacity(isFlipped ? 0 : 1)
            .animation(isFlipped ? .linear : .linear.delay(0.35), value: isFlipped)
        }

        
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.6)) {
                isFlipped.toggle() // Toggle flip state
            }
        }
        
        
        
        .rotationEffect(.degrees(360))
    }
}

struct DiffuserCard_Previews: PreviewProvider {
    static var previews: some View {
        // Set up the model container for preview purposes
        let container: ModelContainer
        do {
            container = try ModelContainer(for: Diffuser.self)
        } catch {
            fatalError("Failed to create ModelContainer for preview: \(error)")
        }

        // Create a mock BluetoothManager
        let bluetoothManager = BluetoothManager()

        // Create a DiffuserManager with the context from the container and the BluetoothManager
        let diffuserManager = DiffuserManager(context: container.mainContext, bluetoothManager: bluetoothManager)

        // Provide the environment object and preview layout
        return DiffuserCard(
            diffuser: Diffuser(
                name: "Living Room Diffuser",
                isConnected: true,
                modelNumber: "AF300",
                serialNumber: "123ABC",
                timerSetting: 120
            )
        )
        .environmentObject(diffuserManager) // Inject the DiffuserManager
        .previewLayout(.sizeThatFits)
    }
}





