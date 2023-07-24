//
//  Thermometer.swift
//  ComposableBleDemo
//
//  Created by Ata Cengiz on 17/07/2023.
//

import Foundation

struct Thermometer: Peripheral {
    
    // MARK: - Properties
    
    let service: UUID = UUID(uuidString: "00001809-0000-1000-8000-00805f9b34fb")!
    var identifier: UUID?
}
