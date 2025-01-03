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
                            Image(systemName: "person")
                            Text("تفضيلات")
                        }
                        .tag(0)
                    
                    // Main View Tab
                    MainView()
                        .tabItem {
                            Image(systemName: "house")
                            Text("الرئيسية")
                        }
                        .tag(1)
                    
                    // Store WebView Tab
                    WebView(url: URL(string: "https://aromatic.sa/categories/4423/أجهزة-التعطير?gad_source=1&gbraid=0AAAAA9cLCG0B3fHpObEw1aGr5L7RYFRBb&gclid=Cj0KCQiA_qG5BhDTARIsAA0UHSKQzyBF5skfRGJwOo314L75QjowNIjlMIVzhCA_rzp3cNiW9PMdyHEaAps5EALw_wcB")!)
                        .tabItem {
                            Image(systemName: "cart")
                            Text("المتجر")
                        }
                        .tag(2)
                }
                
                // "+" Button only on MainView tab
                if selectedTab == 1 {
                    floatingAddButton
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
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationLink(destination: PairDeviceView()) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .padding(.bottom, 70) // Adjust padding to position above TabView
                .padding(.trailing, 170)
            }
        }
    }

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
        let diffuserManager = DiffuserManager(context: container.mainContext, bluetoothManager: bluetoothManager)
        
        return ContentView()
            .environmentObject(diffuserManager)
            .environmentObject(bluetoothManager)
    }
}
