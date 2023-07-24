//
//  KnownDeviceView.swift
//  ComposableBleDemo
//
//  Created by Ata Cengiz on 17/07/2023.
//

import SwiftUI
import ComposableArchitecture

struct KnownDeviceView: View {
    
    let store: StoreOf<KnownDevice>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Text("BLE State")
                        
                        Button (viewStore.clientState.rawValue) {
                            viewStore.send(.connectButtonTapped)
                        }
                        .buttonStyle(.bordered)
                        .tint(viewStore.clientState == .started ? .red : .green)
                    }
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text(viewStore.connection.rawValue)
                    }
                }
            }
        }
    }
}
