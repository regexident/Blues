// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreBluetooth

protocol CBCentralCentralManagerDelegateProtocol {
    @available(iOS 5.0, *)
    func coreCentralManagerDidUpdateState(_ central: CBCentralManagerProtocol)
    
    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CBCentralManagerProtocol, willRestoreState dict: [String : Any])
    
    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CBCentralManagerProtocol, didDiscover peripheral: CBPeripheralProtocol, advertisementData: [String : Any], rssi RSSI: NSNumber)
    
    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CBCentralManagerProtocol, didConnect peripheral: CBPeripheralProtocol)
    
    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CBCentralManagerProtocol, didFailToConnect peripheral: CBPeripheralProtocol, error: Error?)

    @available(iOS 5.0, *)
    func coreCentralManager(_ central: CBCentralManagerProtocol, didDisconnectPeripheral peripheral: CBPeripheralProtocol, error: Error?)
}

protocol CBCentralManagerProtocol: CBManagerProtocol {
    
    var delegate: CBCentralManagerDelegate? { get set }

    @available(iOS 9.0, *)
    var isScanning: Bool { get }

    init()
    init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?)
    
    @available(iOS 7.0, *)
    init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]?)
    
    @available(iOS 7.0, *)
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralProtocol]
    
    @available(iOS 7.0, *)
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralProtocol]
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func stopScan()
    
    func connect(_ peripheral: CBPeripheralProtocol, options: [String : Any]?)
    func cancelPeripheralConnection(_ peripheral: CBPeripheralProtocol)
}

extension CBCentralManager: CBCentralManagerProtocol {
    func connect(_ peripheral: CBPeripheralProtocol, options: [String : Any]?) {
        guard let corePeripheral = protocolCast(peripheral, to: CBPeripheral.self) else {
            return
        }
        self.connect(corePeripheral, options: options)
    }
    
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralProtocol] {
        return self.retrievePeripherals(withIdentifiers: identifiers) as [CBPeripheral]
    }
    
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralProtocol] {
        return self.retrieveConnectedPeripherals(withServices: serviceUUIDs) as [CBPeripheral]
    }
    
    func cancelPeripheralConnection(_ peripheral: CBPeripheralProtocol) {
        guard let corePeripheral = protocolCast(peripheral, to: CBPeripheral.self) else {
            return
        }
        return self.cancelPeripheralConnection(corePeripheral)
    }
}
