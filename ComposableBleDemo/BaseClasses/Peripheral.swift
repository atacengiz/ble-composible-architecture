//
//  Peripheral.swift
//  ComposableBleDemo
//
//  Created by Ata Cengiz on 17/07/2023.
//

import Foundation

protocol Peripheral {
    
    // MARK: - Properties
    
    var service: UUID { get }
    var identifier: UUID? { set get }
}
