//
//  ComposableBleDemoApp.swift
//  ComposableBleDemo
//
//  Created by Ata Cengiz on 17/07/2023.
//

import SwiftUI
import ComposableArchitecture

@main
struct ComposableBleDemoApp: App {
    
    let store: StoreOf<Root> = Store(initialState: Root.State()) {
        Root()
            .signpost()
            ._printChanges()
    }
    
    var body: some Scene {
        WindowGroup {
            KnownDeviceView(store: self.store.scope(state: \.knownDevice,
                                                    action: Root.Action.knownDevice))
        }
    }
}
