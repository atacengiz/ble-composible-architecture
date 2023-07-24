//
//  Root.swift
//  ComposableBleDemo
//
//  Created by Ata Cengiz on 24/07/2023.
//

import Foundation
import ComposableArchitecture

struct Root: ReducerProtocol {
    
    struct State: Equatable {
        var knownDevice = KnownDevice.State()
    }
    
    enum Action {
        case onAppear
        case knownDevice(KnownDevice.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
                case .onAppear:
                    state = .init()
                    return .none
                    
                default:
                    return .none
            }
        }
        
        Scope(state: \.knownDevice, action: /Action.knownDevice) {
            KnownDevice()
        }
    }
}
