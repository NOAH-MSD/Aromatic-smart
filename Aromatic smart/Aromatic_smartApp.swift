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
            print("Creating sharedModelContainer with schema: \(schema)")
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
        print("Initialized BluetoothManager: \(bluetoothManager)")

        // Initialize the DiffuserManager with context and bluetoothManager
        let diffuserManager = DiffuserManager(context: sharedModelContainer.mainContext, bluetoothManager: bluetoothManager)
        _diffuserManager = StateObject(wrappedValue: diffuserManager)
        print("Initialized DiffuserManager with BluetoothManager: \(bluetoothManager) and context: \(sharedModelContainer.mainContext)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(diffuserManager) // Inject DiffuserManager as an environment object
                .environmentObject(bluetoothManager) // Inject BluetoothManager if needed
                .onAppear {
                    print("ContentView appeared with DiffuserManager: \(diffuserManager) and BluetoothManager: \(bluetoothManager)")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
