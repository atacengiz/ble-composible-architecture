//
//  ComposableBleDemoApp.swift
//  ComposableBleDemo
//
//  Created by Ata Cengiz on 17/07/2023.
//

import SwiftUI

@main
struct ComposableBleDemoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
