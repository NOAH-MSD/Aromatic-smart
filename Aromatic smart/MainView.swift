import SwiftUI
import SwiftData

struct MainView: View {
    @EnvironmentObject var diffuserManager: DiffuserManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Query var diffusers: [Diffuser]

    var body: some View {
        NavigationView { // Wrap everything in NavigationView
            VStack {
                // Logo at the top center
                logoView

                // Main content: either the list of diffusers or a placeholder message
                if diffusers.isEmpty {
                    noDevicesView
                } else {
                    devicesScrollView
                }
            }
            
            .padding()
        }
    }
}

// MARK: - Subviews

extension MainView {
    private var logoView: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(width: 140, height: 140)
    }



    private var noDevicesView: some View {
        VStack {
            Text("لا يوجد أجهزة حاليا اضغط الزر أدناه لإضافة جهاز جديد")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .foregroundColor(Color(red: 21 / 255, green: 47 / 255, blue: 119 / 255))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var devicesScrollView: some View {
        ScrollView {
            VStack(spacing: 10) { // Space between cards
                ForEach(diffusers) { diffuser in
                    
                        DiffuserCard(diffuser: diffuser)
                            .frame(width: UIScreen.main.bounds.width - 40, height: 410)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    
                }
            }
            
        }
    }
}

// MARK: - Preview

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a shared model container for the preview
        let container = try! ModelContainer(for: Diffuser.self)

        // Use the singleton instance of BluetoothManager
        let bluetoothManager = BluetoothManager.shared
        let diffuserManager = DiffuserManager(context: container.mainContext, bluetoothManager: bluetoothManager)

        return MainView()
            .environment(\.modelContext, container.mainContext)
            .environmentObject(diffuserManager)
            .environmentObject(bluetoothManager)
    }
}
