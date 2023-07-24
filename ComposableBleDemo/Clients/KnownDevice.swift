//
//  KnownDevice.swift
//  ComposableBleDemo
//
//  Created by Ata Cengiz on 21/07/2023.
//

import Foundation
import ComposableArchitecture
import OSLog

struct KnownDevice: ReducerProtocol {
    
    @Dependency(\.bleClient) var bleClient

    struct State: Equatable {
        var clientState: ClientState = .stopped
        var connection: ConnectivityState = .disconnected
        
        enum ClientState: String {
            case started = "Start"
            case stopped = "Stop"
        }
        
        enum ConnectivityState: String {
            case connected = "Connected"
            case connecting = "Connecting..."
            case disconnected = "Disconnected"
        }
    }
    
    enum Action: Equatable {
        static func == (lhs: KnownDevice.Action, rhs: KnownDevice.Action) -> Bool {
            return false
        }
        
        case connectButtonTapped
        case connecting
        case didConnect
        case didDisconnect
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        
        switch action {
            case .connectButtonTapped:
                switch state.clientState {
                    case .started:
                        state.clientState = .stopped
                        
                        return .run { send in
                            await bleClient.stop()
                        }
                    case .stopped:
                        state.clientState = .started
                        
                        return .run { [connection = state.connection] send in
                            let bleActions = await bleClient.start()
                            
                                for await bleAction in bleActions {
                                    
                                    switch bleAction {
                                        case .didChangeState(state: let state):
                                            Logger().debug("KnownDevice:didChangeState - state \(state.rawValue)")
                                            
                                            switch state {
                                                case .poweredOn:
                                                    await bleClient.search(Thermometer())
                                                default:
                                                    break
                                            }
                                        case .didDiscover(peripheral: let peripheral, advertisementData: let advertisementData, RSSI: let RSSI):
                                            Logger().debug("KnownDevice:didDiscover - didDiscover \(peripheral), advertisementData: \(advertisementData) let RSSI: \(RSSI)")
                                            
                                            if connection == .disconnected {
                                                await bleClient.connect(peripheral)
                                            }
                                                                                        
                                            await send(.connecting)
                                            
                                        case .didConnect(peripheral: let peripheral):
                                            Logger().debug("KnownDevice:didConnect - didConnect \(peripheral)")
                                            
                                            await send(.didConnect)
                                        case .didFailToConnect(peripheral: let peripheral):
                                            Logger().debug("KnownDevice:didFailToConnect - didFailToConnect \(peripheral)")
                                            
                                            await send(.didDisconnect)
                                }
                            }
                        }
                }
            case .connecting:
                state.connection = .connecting
                
                return .none
            case .didConnect:
                state.connection = .connected
                
                return .none
            case .didDisconnect:
                state.connection = .disconnected
                
                return .none
        }
    }
}
