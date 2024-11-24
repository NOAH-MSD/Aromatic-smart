//
//  Aromatic_smartApp.swift
//  Aromatic smart
//
//  Created by عارف on 20/11/2024.
//

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

    // Create the DiffuserManager and pass the ModelContainer
    @StateObject private var diffuserManager: DiffuserManager

    init() {
        let diffuserManager = DiffuserManager(context: sharedModelContainer.mainContext)
        _diffuserManager = StateObject(wrappedValue: diffuserManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(diffuserManager) // Inject DiffuserManager as an environment object
        }
        .modelContainer(sharedModelContainer)
    }
}
