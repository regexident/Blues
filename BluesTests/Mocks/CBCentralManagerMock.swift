//
//  CentralManagerMock.swift
//  BluesTests
//
//  Created by Michał Kałużny on 12/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

@testable import Blues

class CBCentralManagerMock: CoreCentralManagerProtocol {
    required convenience init() {
        self.init(delegate: nil, queue: nil, options: nil)
    }
    
    var delegate: CBCentralManagerDelegate?
    var genericDelegate: CoreCentralCentralManagerDelegateProtocol? = nil
    
    var isScanning: Bool = false
    var state: CBManagerState = .poweredOn {
        didSet {
            self.genericDelegate?.coreCentralManagerDidUpdateState(self)
        }
    }
    
    var retrievablePeripherals: [UUID: [String: Any]] = [:]
    
    required convenience init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?) {
        self.init(delegate: delegate, queue: queue, options: nil)
    }
    
    required init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]?) {
        self.delegate = delegate
    }
    
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CorePeripheralProtocol] {
        return []
    }
    
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CorePeripheralProtocol] {
        return []
    }
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        self.isScanning = true
    }
    
    func stopScan() {
        self.isScanning = false
    }
    
    func connect(_ peripheral: CorePeripheralProtocol, options: [String : Any]?) {
    }
    
    func cancelPeripheralConnection(_ peripheral: CorePeripheralProtocol) {
    }
}
