//
//  CoreCentralManager.swift
//  Blues
//
//  Created by Michał Kałużny on 12/09/2017.
//  Copyright © 2017 NWTN Berlin. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol CoreCentralCentralManagerDelegateProtocol {
    @available(iOS 5.0, *)
    func coreCentralManagerDidUpdateState(_ central: CoreCentralManagerProtocol)
    
    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CoreCentralManagerProtocol, willRestoreState dict: [String : Any])
    
    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CoreCentralManagerProtocol, didDiscover peripheral: CorePeripheralProtocol, advertisementData: [String : Any], rssi RSSI: NSNumber)
    
    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CoreCentralManagerProtocol, didConnect peripheral: CorePeripheralProtocol)
    
    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CoreCentralManagerProtocol, didFailToConnect peripheral: CorePeripheralProtocol, error: Error?)

    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CoreCentralManagerProtocol, didDisconnectPeripheral peripheral: CorePeripheralProtocol, error: Error?)
}

protocol CoreCentralManagerProtocol: CoreManagerProtocol {
    
    weak var delegate: CBCentralManagerDelegate? { get set }

    @available(iOS 9.0, *)
    var isScanning: Bool { get }

    init()
    init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?)
    
    @available(iOS 7.0, *)
    init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]?)
    
    @available(iOS 7.0, *)
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CorePeripheralProtocol]
    
    @available(iOS 7.0, *)
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CorePeripheralProtocol]
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func stopScan()
    
    func connect(_ peripheral: CorePeripheralProtocol, options: [String : Any]?)
    func cancelPeripheralConnection(_ peripheral: CorePeripheralProtocol)
}

extension CBCentralManager: CoreCentralManagerProtocol {
    func connect(_ peripheral: CorePeripheralProtocol, options: [String : Any]?) {
        guard let corePeripheral = protocolCast(peripheral, to: CBPeripheral.self) else {
            return
        }
        
        connect(corePeripheral, options: options)
    }
    
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CorePeripheralProtocol] {
        return retrievePeripherals(withIdentifiers: identifiers)
    }
    
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CorePeripheralProtocol] {
        return retrieveConnectedPeripherals(withServices: serviceUUIDs)
    }
    
    func cancelPeripheralConnection(_ peripheral: CorePeripheralProtocol) {
        return cancelPeripheralConnection(peripheral)
    }
}

