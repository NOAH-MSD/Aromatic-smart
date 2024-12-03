import SwiftUI
import SwiftData

@main
struct Aromatic_smartApp: App {
    let sharedModelContainer: ModelContainer
    @StateObject private var bluetoothManager: BluetoothManager
    @StateObject private var diffuserManager: DiffuserManager

    init() {
        // Initialize sharedModelContainer
        let schema = Schema([Diffuser.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            print("Creating sharedModelContainer with schema: \(schema)")
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Use the singleton instance
        let bluetoothManagerInstance = BluetoothManager.shared // <-- Use the singleton
        let diffuserManagerInstance = DiffuserManager(
            context: sharedModelContainer.mainContext,
            bluetoothManager: bluetoothManagerInstance
        )

        // Initialize @StateObject properties using local instances
        _bluetoothManager = StateObject(wrappedValue: bluetoothManagerInstance)
        _diffuserManager = StateObject(wrappedValue: diffuserManagerInstance)

        print("Initialized DiffuserManager with BluetoothManager: \(Unmanaged.passUnretained(bluetoothManagerInstance).toOpaque()) and context: \(sharedModelContainer.mainContext)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(diffuserManager) // Inject DiffuserManager as an environment object
                .environmentObject(bluetoothManager) // Inject BluetoothManager as an environment object
                .onAppear {
                    print("ContentView appeared with DiffuserManager: \(Unmanaged.passUnretained(diffuserManager).toOpaque()) and BluetoothManager: \(Unmanaged.passUnretained(bluetoothManager).toOpaque())")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
