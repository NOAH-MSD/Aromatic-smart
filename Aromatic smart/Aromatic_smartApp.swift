import SwiftUI
import SwiftData

@main
struct Aromatic_smartApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Diffuser.self, // Include Diffuser in the schema
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // Create the DiffuserManager and BluetoothManager
    @StateObject private var diffuserManager: DiffuserManager
    @StateObject private var bluetoothManager: BluetoothManager

    init() {
        // Initialize the BluetoothManager
        let bluetoothManager = BluetoothManager()
        _bluetoothManager = StateObject(wrappedValue: bluetoothManager)

        // Initialize the DiffuserManager with context and bluetoothManager
        let diffuserManager = DiffuserManager(context: sharedModelContainer.mainContext, bluetoothManager: bluetoothManager)
        _diffuserManager = StateObject(wrappedValue: diffuserManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(diffuserManager) // Inject DiffuserManager as an environment object
                .environmentObject(bluetoothManager) // Inject BluetoothManager if needed
        }
        .modelContainer(sharedModelContainer)
    }
}
