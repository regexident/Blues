// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
    
    var delegate: CBCentralManagerDelegate? { get set }

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
        self.connect(corePeripheral, options: options)
    }
    
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CorePeripheralProtocol] {
        return self.retrievePeripherals(withIdentifiers: identifiers) as [CBPeripheral]
    }
    
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CorePeripheralProtocol] {
        return self.retrieveConnectedPeripherals(withServices: serviceUUIDs) as [CBPeripheral]
    }
    
    func cancelPeripheralConnection(_ peripheral: CorePeripheralProtocol) {
        guard let corePeripheral = protocolCast(peripheral, to: CBPeripheral.self) else {
            return
        }
        return self.cancelPeripheralConnection(corePeripheral)
    }
}
