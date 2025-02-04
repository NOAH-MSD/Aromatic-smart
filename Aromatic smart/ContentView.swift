import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 1 // Default to MainView
    @EnvironmentObject var diffuserManager: DiffuserManager
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        NavigationView {
            ZStack {
                // Main TabView
                TabView(selection: $selectedTab) {
                    // Preferences Tab
                    UserProfileView()
                        .tabItem {
                            Image(systemName: "info.circle.fill")
                            Text("Explore")
                        }
                        .tag(0)

                    // Main View Tab
                    MainView()
                        .tabItem {
                            Image(systemName: "house")
                            Text("Main")
                        }
                        .tag(1)

                    // Store WebView Tab
                    WebView(url: URL(string: "https://aromatic.sa/categories/4423/أجهزة-التعطير")!)
                        .tabItem {
                            Image(systemName: "cart")
                            Text("Store")
                        }
                        .tag(2)
                }
                .accentColor(.white)  // Apply white color to icons and text

                
                // "+" Button only on MainView tab
                if selectedTab == 1 {
                    
                }
            }
            .navigationBarTitle("Aromatic App") // Title for NavigationView
            .navigationBarHidden(true)         // Hide navigation bar if needed
        }
        .onAppear {
            debugManagers()
        }
    }
}

// MARK: - Subviews and Helpers

extension ContentView {
    /// Floating "+" button for adding a device
 



    /// Debug environment objects
    private func debugManagers() {
        print("ContentView using DiffuserManager: \(Unmanaged.passUnretained(diffuserManager).toOpaque()) and BluetoothManager: \(Unmanaged.passUnretained(bluetoothManager).toOpaque())")
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: Diffuser.self)
        let bluetoothManager = BluetoothManager.shared
        let diffuserManager = DiffuserManager(
            context: container.mainContext,
            bluetoothManager: bluetoothManager,
            diffuserAPI: bluetoothManager.diffuserAPI!  // Force unwrapped here as well
        )
        
        return ContentView()
            .environmentObject(diffuserManager)
            .environmentObject(bluetoothManager)
    }
}

