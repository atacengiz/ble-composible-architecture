//
//  BLEClient.swift
//  ComposableBleDemo
//
//  Created by Ata Cengiz on 17/07/2023.
//

import Foundation
import CoreBluetooth
import OSLog
import ComposableArchitecture
import Combine

extension CBPeripheral {
    
    open override var description: String {
        return "Peripheral: \(self.identifier)"
    }
}

struct BLEClient {
    
    enum Action {
        case didChangeState(state: CBManagerState)
        case didDiscover(peripheral: CBPeripheral, advertisementData: [String: Any], RSSI: NSNumber)
        case didConnect(peripheral: CBPeripheral)
        case didFailToConnect(peripheral: CBPeripheral)
    }
    
    var start: @Sendable () async -> AsyncStream<Action>
    var search: @Sendable (Peripheral) async -> Void
    var connect: @Sendable (CBPeripheral) async -> Void
    var stop: @Sendable () async -> Void
}

extension BLEClient: DependencyKey {
    
    static var liveValue: Self {
        return Self(
            start: { await BLEActor.shared.start() },
            search: { await BLEActor.shared.searchFor(peripheral: $0) },
            connect: { await BLEActor.shared.connect(peripheral: $0) },
            stop: { await BLEActor.shared.stop() }
        )
        
        final actor BLEActor: GlobalActor {
            
            typealias Dependency = (centralManager: CBCentralManager, delegate: Delegate)

            var dependency: Dependency?

            static var shared: BLEActor = BLEActor()
            
            // MARK: - Properties

            static let restorationIdentifier: String = "ComposableBleDemo.BLEClientRestoration"
            
            private let dispatchQueue: DispatchQueue = DispatchQueue(label: "ComposableBleDemo.BLEClientQueue", qos: .default)
            
            private var searchList: [any Peripheral] = []
            
            // MARK: - Constructor
            
            func start() -> AsyncStream<Action> {
                let delegate = Delegate()
                
                let centralManager = CBCentralManager(delegate: delegate,
                                                      queue: dispatchQueue,
                                                      options: [
                                                        CBCentralManagerOptionShowPowerAlertKey: NSNumber(value: true)
                                                      ])
                
                var continuation: AsyncStream<Action>.Continuation!
                
                let stream = AsyncStream<Action> {
                    $0.onTermination = { _ in
                        centralManager.stopScan()
                        
                        Task { await self.releaseDependency() }
                    }
                    
                    continuation = $0
                }
                
                delegate.continuation = continuation
                
                self.dependency = (centralManager, delegate)
                
                return stream
            }
            
            // MARK: - Public functions
            
            func searchFor(peripheral: any Peripheral) async {                
                searchList.append(peripheral)
                
                startSearching()
            }
            
            func connect(peripheral: CBPeripheral) async {
                dependency?.delegate.connectedDevices.append(peripheral)
                dependency?.centralManager.connect(peripheral)
            }
            
            func getConnectedDevice(of peripheral: any Peripheral) -> CBPeripheral? {
                return dependency?.delegate.connectedDevices.first(where: { $0.identifier == peripheral.identifier })
            }
            
            func stop() {
                dependency?.delegate.continuation?.finish()
            }
            
            // MARK: - Private functions
            
            private func startSearching() {
                guard let centralManager = dependency?.centralManager else { return }
                
                let serviceList = searchList.map({ CBUUID(nsuuid: $0.service) })
                
                Logger().debug("BLEClient:startSearching - started searching for \(serviceList)")

                centralManager.scanForPeripherals(withServices: serviceList)
            }
            
            func releaseDependency() {
                dependency = nil
            }
            
            final class Delegate: NSObject, CBCentralManagerDelegate {
                
                var continuation: AsyncStream<Action>.Continuation?
                var connectedDevices: [CBPeripheral] = []

                func centralManagerDidUpdateState(_ central: CBCentralManager) {
                    Logger().debug("BLEClient:centralManagerDidUpdateState - state: \(central.state.rawValue)")
                    continuation?.yield(.didChangeState(state: central.state))
                }
                
                func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
                    Logger().debug("BLEClient:didDiscover - peripheral: \(peripheral)")
                    continuation?.yield(.didDiscover(peripheral: peripheral,
                                                     advertisementData: advertisementData,
                                                     RSSI: RSSI))
                }
                
                func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
                    Logger().debug("BLEClient:didConnect - peripheral: \(peripheral)")
                    continuation?.yield(.didConnect(peripheral: peripheral))
                }
                
                func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
                    Logger().debug("BLEClient:didFailToConnect - peripheral: \(peripheral)")
                    continuation?.yield(.didFailToConnect(peripheral: peripheral))
                    
                    connectedDevices.removeAll(where: { $0.identifier == peripheral.identifier })
                }
            }
        }
    }
    
    static var testValue = Self(
        start: unimplemented("\(Self.self).start"),
        search: unimplemented("\(Self.self).search"),
        connect: unimplemented("\(Self.self).connect"),
        stop: unimplemented("\(Self.self).stop")
    )
}

extension DependencyValues {
    var bleClient: BLEClient {
        get { self[BLEClient.self] }
        set { self[BLEClient.self] = newValue }
    }
}
